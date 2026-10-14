import asyncio
import json
import logging
import uuid
from collections import Counter
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from redis.asyncio import Redis

from app.core import goden, kafka
from app.core.dependencies import TokenData
from app.modules.cart.repository import CartRepository, CatalogReadRepository
from app.modules.couriers.repository import CourierRepository
from app.modules.orders.exceptions import (
    CartEmptyError,
    CourierHasActiveOrderError,
    CourierNotOnShiftError,
    CourierOutOfZoneError,
    DeliveryAddressRequiredError,
    DeliveryZoneError,
    ItemNotSoldError,
    MinOrderPriceError,
    OrderAccessDeniedError,
    OrderInvalidStatusError,
    OrderNotFoundError,
    OrderNotOfferedError,
    OutletClosedError,
    OutletNotAcceptingError,
    OutletNotFoundError,
    PaymentMethodNotFoundError,
    PickupOnlyError,
    ProductsShortageError,
)
from app.modules.orders.models import DeliveryType, OrderStatus
from app.modules.orders.repository import OrderRepository, OutletReadRepository
from app.modules.customers.schemas import AddressResponse
from app.modules.orders.schemas import (
    OrderCreate,
    OrderFilters,
    OrderItemResponse,
    OrderListResponse,
    OrderResponse,
    StatusHistoryResponse,
)
from app.modules.shifts.repository import ShiftRepository

logger = logging.getLogger(__name__)

_COURIER_STATE_TTL = 1800
_COURIER_STATE_KEY = "courier:{courier_id}:state"

# Параметры доставки платформы
_DELIVERY_RADIUS_KM = 8       # максимальный радиус доставки
_FREE_DELIVERY_UP_TO_KM = 2   # до этого расстояния - только сбор точки
_PRICE_PER_KM = Decimal("25") # надбавка за каждый км сверх порога

# Оффер курьеру
_OFFER_TTL_SEC = 30           # время на принятие заказа курьером
_OFFER_KEY = "offer:{order_id}"  # Redis-ключ с TTL, значение = courier_id
_OFFER_REJECTED_KEY = "offer:{order_id}:rejected"  # SET отказавшихся курьеров


class OrderService:
    def __init__(
        self,
        order_repo: OrderRepository,
        outlet_repo: OutletReadRepository,
        cart_repo: CartRepository,
        catalog_repo: CatalogReadRepository,
        courier_repo: CourierRepository,
        shift_repo: ShiftRepository,
        redis: Redis,
    ) -> None:
        self._orders = order_repo
        self._outlets = outlet_repo
        self._cart = cart_repo
        self._catalog = catalog_repo
        self._couriers = courier_repo
        self._shifts = shift_repo
        self._redis = redis

    # --- Покупатель ---

    async def create_order(self, current_user: TokenData, data: OrderCreate) -> OrderResponse:
        # 1. Корзина не пустая
        cart_items = await self._cart.list_by_customer(current_user.user_id)
        if not cart_items:
            raise CartEmptyError()

        # 2. Точка существует и активна
        outlet = await self._outlets.get_outlet(data.outlet_id)
        if not outlet or not outlet["is_active"]:
            raise OutletNotFoundError()

        # 3. Точка сейчас открыта
        self._check_outlet_open(outlet)

        # 4. Способ оплаты принадлежит покупателю
        await self._check_payment_method(current_user.user_id, data.customer_payment_method_id)

        # 5. Для доставки - нужен адрес с координатами, проверяем радиус
        address = None
        delivery_fee = Decimal("0")
        if data.delivery_type == DeliveryType.delivery:
            address = await self._resolve_delivery_address(data)
            if not address.latitude or not address.longitude:
                raise DeliveryAddressRequiredError()
            distance_km = await self._outlets.get_distance_km(
                data.outlet_id, float(address.latitude), float(address.longitude)
            )
            if distance_km is None or distance_km > _DELIVERY_RADIUS_KM:
                raise DeliveryZoneError()
            delivery_fee = self._calc_delivery_fee(outlet, distance_km)

        # 6. Собираем snapshot позиций из catalog_items
        snapshot_items = []
        subtotal = Decimal("0.00")
        goden_point = outlet["goden_point_id"]
        portions: Counter[uuid.UUID] = Counter()
        for bucket_item in cart_items:
            catalog = await self._catalog.get_catalog_item(bucket_item.catalog_item_id)
            if not catalog:
                continue
            if goden_point:
                # у заведения с точкой Goden продаются только товары, связанные с блюдами
                if catalog["goden_dish_id"] is None:
                    raise ItemNotSoldError(catalog["name"])
                portions[catalog["goden_dish_id"]] += bucket_item.quantity
            price = Decimal(str(catalog["price"]))
            subtotal += price * bucket_item.quantity
            snapshot_items.append({
                "catalog_item_id": bucket_item.catalog_item_id,
                "name": catalog["name"],
                "price": float(price),
                "quantity": bucket_item.quantity,
            })

        # 7. Минимальная сумма заказа
        if outlet["min_order_price"] and subtotal < outlet["min_order_price"]:
            raise MinOrderPriceError(outlet["min_order_price"])
        total_price = subtotal + delivery_fee

        # 8. Заказ на кухню точки Goden: последним перед сохранением, после всех проверок Мигома
        goden_order = await self._order_in_goden(goden_point, data.outlet_id, portions) if goden_point else None
        try:
            order = await self._save_order(
                current_user, data, cart_items, total_price, snapshot_items, goden_point, goden_order
            )
        except Exception:
            # Goden принял заказ, а Мигом его не сохранил: продукты возвращаются на склад
            if goden_order:
                await self._cancel_in_goden(goden_point, uuid.UUID(goden_order["id"]), "не сохранён в Мигоме")
            raise

        # 12. Для доставки - сразу предлагаем заказ ближайшему курьеру
        if data.delivery_type == DeliveryType.delivery and address:
            try:
                await self._offer_order_to_next_courier(
                    order.id,
                    float(address.latitude),
                    float(address.longitude),
                )
            except Exception:
                logger.exception("Ошибка при поиске курьера для заказа %s", order.id)

        return await self._get_full_response(order.id)

    async def _order_in_goden(self, point_id: uuid.UUID, outlet_id: int, portions: Counter) -> dict:
        """Оформляет заказ в Goden. Нехватка продуктов, неподтверждённая точка - 409 без заказа."""
        if not await goden.confirmed(point_id, outlet_id):
            raise OutletNotAcceptingError()
        try:
            placed = await goden.place_order(point_id, dict(portions))
        except goden.GodenRefusedError as e:
            logger.warning("Goden отказал в заказе на точке %s: %s", point_id, e)
            # 403 - точка больше не подключена; остальное - блюдо сняли с продажи
            if e.status_code == 403:
                raise OutletNotAcceptingError()
            raise ProductsShortageError([])
        if placed["status"] != "accepted":
            names = [s["product"]["name"] for s in placed.get("shortages", []) if s.get("product")]
            raise ProductsShortageError(names)
        return placed

    async def _cancel_in_goden(self, point_id: uuid.UUID, order_id: uuid.UUID, reason: str) -> None:
        """Отменяет заказ в Goden. Сбой не мешает Мигому: продукты остаются списанными, это в журнале."""
        try:
            await goden.cancel_order(point_id, order_id)
        except (goden.GodenUnavailableError, goden.GodenRefusedError) as e:
            logger.warning("Заказ Goden %s (%s) не отменён, продукты остались списанными: %s", order_id, reason, e)

    async def _return_to_goden(self, order) -> None:
        """До начала готовки (new, assigned) отмена возвращает продукты на склад Goden. Позже кухня
        уже готовит, и отмена меняет только статус в Мигоме."""
        if order.goden_order_id and order.status in (OrderStatus.new, OrderStatus.assigned):
            await self._cancel_in_goden(order.goden_point_id, order.goden_order_id, f"отмена заказа {order.id}")

    async def _save_order(self, current_user, data, cart_items, total_price, snapshot_items, goden_point, goden_order):
        # 9. Создаём заказ
        order = await self._orders.create(
            customer_id=current_user.user_id,
            company_id=cart_items[0].company_id,
            outlet_id=data.outlet_id,
            delivery_type=data.delivery_type,
            customer_payment_method_id=data.customer_payment_method_id,
            total_price=float(total_price),
            customer_address_id=data.customer_address_id,
            comment=data.comment,
            leave_at_door=data.leave_at_door,
            goden_point_id=goden_point,
            goden_order_id=uuid.UUID(goden_order["id"]) if goden_order else None,
        )
        await self._orders.add_items(order.id, snapshot_items)
        await self._orders.add_status_history(order.id, OrderStatus.new, current_user.user_id)

        # 10. Очищаем корзину
        await self._cart.clear_all(current_user.user_id)

        # 11. Kafka
        await kafka.publish_event("order.created", {
            "order_id": order.id,
            "outlet_id": order.outlet_id,
            "customer_id": order.customer_id,
            "company_id": order.company_id,
            "delivery_type": data.delivery_type.value,
            "items": [{"catalog_item_id": i["catalog_item_id"], "quantity": i["quantity"]} for i in snapshot_items],
        })
        return order

    async def get_my_orders(
        self, current_user: TokenData, offset: int, limit: int
    ) -> OrderListResponse:
        orders, total = await self._orders.list_by_customer(
            current_user.user_id, offset=offset, limit=limit
        )
        return OrderListResponse(
            items=list(await asyncio.gather(*[self._to_response(o) for o in orders])),
            total=total,
        )

    async def get_order(self, current_user: TokenData, order_id: int) -> OrderResponse:
        order = await self._orders.get_by_id(order_id)
        if not order:
            raise OrderNotFoundError()
        if order.customer_id != current_user.user_id:
            raise OrderAccessDeniedError()
        return await self._to_response(order)

    async def customer_cancel(self, current_user: TokenData, order_id: int) -> OrderResponse:
        order = await self._orders.get_by_id(order_id)
        if not order:
            raise OrderNotFoundError()
        if order.customer_id != current_user.user_id:
            raise OrderAccessDeniedError()
        if order.status != OrderStatus.new:
            raise OrderInvalidStatusError("Покупатель может отменить заказ только в статусе 'new'")

        await self._return_to_goden(order)
        updated = await self._orders.update_status(order, OrderStatus.cancelled, current_user.user_id)
        await self._publish_status_event(updated)
        return await self._to_response(updated)

    async def customer_receive(self, current_user: TokenData, order_id: int) -> OrderResponse:
        """Подтверждение самовывоза покупателем."""
        order = await self._orders.get_by_id(order_id)
        if not order:
            raise OrderNotFoundError()
        if order.customer_id != current_user.user_id:
            raise OrderAccessDeniedError()
        if order.delivery_type != DeliveryType.pickup:
            raise OrderInvalidStatusError("Этот эндпоинт только для заказов самовывоза")
        if order.status != OrderStatus.ready_for_pickup:
            raise OrderInvalidStatusError("Заказ должен быть в статусе 'ready_for_pickup'")

        updated = await self._orders.update_status(order, OrderStatus.received, current_user.user_id)
        await self._publish_status_event(updated)
        return await self._to_response(updated)

    # --- Курьер ---

    async def get_available_orders(self, current_user: TokenData) -> list[OrderResponse]:
        courier = await self._couriers.get_or_create(current_user.user_id)
        orders = await self._orders.list_available_for_courier(courier.id)
        return list(await asyncio.gather(*[self._to_response(o) for o in orders]))

    async def get_active_order(self, current_user: TokenData) -> OrderResponse:
        courier = await self._couriers.get_or_create(current_user.user_id)
        order = await self._orders.get_active_by_courier(courier.id)
        if not order:
            raise OrderNotFoundError()
        return await self._to_response(order)

    async def courier_accept(self, current_user: TokenData, order_id: int) -> OrderResponse:
        order = await self._orders.get_by_id(order_id)
        if not order:
            raise OrderNotFoundError()
        if order.status != OrderStatus.new:
            raise OrderInvalidStatusError("Можно принять только заказ в статусе 'new'")
        if order.delivery_type != DeliveryType.delivery:
            raise PickupOnlyError()

        courier = await self._couriers.get_or_create(current_user.user_id)

        # Курьер в активной смене
        shift = await self._shifts.get_active(courier.id)
        if not shift:
            raise CourierNotOnShiftError()

        # Нет другого активного заказа
        active = await self._orders.get_active_by_courier(courier.id)
        if active:
            raise CourierHasActiveOrderError()

        # Проверяем что заказ был предложен именно этому курьеру
        offer_key = _OFFER_KEY.format(order_id=order_id)
        offered_to = await self._redis.get(offer_key)
        if not offered_to or int(offered_to) != courier.id:
            raise OrderNotOfferedError()

        # Сбрасываем оффер и список отказавшихся
        await self._redis.delete(offer_key)
        await self._redis.delete(_OFFER_REJECTED_KEY.format(order_id=order_id))
        await self._orders.clear_offer(order)

        updated = await self._orders.assign_courier(order, courier.id, current_user.user_id)

        # Обновляем Redis-состояние курьера
        await self._set_courier_active_order(courier.id, order_id)

        await kafka.publish_event("courier.assigned", {
            "order_id": order_id,
            "courier_id": courier.id,
            "customer_id": order.customer_id,
            "outlet_id": order.outlet_id,
        })
        await self._publish_status_event(updated)
        return await self._to_response(updated)

    async def courier_reject(self, current_user: TokenData, order_id: int) -> None:
        """Курьер отказался от оффера - предлагаем следующему."""
        order = await self._orders.get_by_id(order_id)
        if not order:
            raise OrderNotFoundError()
        if order.status != OrderStatus.new:
            raise OrderInvalidStatusError("Можно отказаться только от заказа в статусе 'new'")

        courier = await self._couriers.get_or_create(current_user.user_id)

        # Проверяем что оффер был именно этому курьеру
        offer_key = _OFFER_KEY.format(order_id=order_id)
        offered_to = await self._redis.get(offer_key)
        if not offered_to or int(offered_to) != courier.id:
            raise OrderNotOfferedError()

        # Добавляем в список отказавшихся (TTL 10 мин - дольше цепочки попыток)
        rejected_key = _OFFER_REJECTED_KEY.format(order_id=order_id)
        await self._redis.sadd(rejected_key, str(courier.id))
        await self._redis.expire(rejected_key, 600)

        # Сбрасываем текущий оффер и ищем следующего курьера
        await self._redis.delete(offer_key)
        await self._orders.clear_offer(order)

        address = await self._orders.get_address(order.customer_address_id) if order.customer_address_id else None
        if address and address.latitude and address.longitude:
            await self._offer_order_to_next_courier(
                order_id, float(address.latitude), float(address.longitude)
            )

    async def courier_pickup(self, current_user: TokenData, order_id: int) -> OrderResponse:
        """Курьер забрал заказ: ready_for_pickup → in_delivery.
        Также допускает assigned/assembling - автоматически проходит промежуточные статусы."""
        order, courier = await self._get_courier_order(current_user, order_id)

        allowed = {OrderStatus.assigned, OrderStatus.assembling, OrderStatus.ready_for_pickup}
        if order.status not in allowed:
            raise OrderInvalidStatusError("Заказ должен быть в статусе 'assigned', 'assembling' или 'ready_for_pickup'")

        # Прогоняем промежуточные статусы если нужно
        intermediate = []
        if order.status == OrderStatus.assigned:
            intermediate = [OrderStatus.assembling, OrderStatus.ready_for_pickup]
        elif order.status == OrderStatus.assembling:
            intermediate = [OrderStatus.ready_for_pickup]

        for status in intermediate:
            order = await self._orders.update_status(order, status, current_user.user_id)

        updated = await self._orders.update_status(order, OrderStatus.in_delivery, current_user.user_id)
        await self._publish_status_event(updated)
        return await self._to_response(updated)

    async def courier_deliver(self, current_user: TokenData, order_id: int) -> OrderResponse:
        """Курьер доставил: in_delivery → delivered. Ждёт подтверждения от покупателя."""
        order, courier = await self._get_courier_order(current_user, order_id)
        if order.status != OrderStatus.in_delivery:
            raise OrderInvalidStatusError("Заказ должен быть в статусе 'in_delivery'")

        updated = await self._orders.update_status(order, OrderStatus.delivered, current_user.user_id)
        await self._publish_status_event(updated)
        return await self._to_response(updated)

    async def customer_confirm(self, current_user: TokenData, order_id: int) -> OrderResponse:
        """Покупатель подтвердил получение доставки: delivered → received."""
        order = await self._orders.get_by_id(order_id)
        if not order:
            raise OrderNotFoundError()
        if order.customer_id != current_user.user_id:
            raise OrderAccessDeniedError()
        if order.delivery_type != DeliveryType.delivery:
            raise OrderInvalidStatusError("Этот эндпоинт только для заказов с доставкой")
        if order.status != OrderStatus.delivered:
            raise OrderInvalidStatusError("Заказ должен быть в статусе 'delivered'")

        updated = await self._orders.update_status(order, OrderStatus.received, current_user.user_id)

        # Освобождаем курьера только после подтверждения покупателем
        if updated.courier_id:
            await self._clear_courier_active_order(updated.courier_id)

        await self._publish_status_event(updated)
        return await self._to_response(updated)

    # --- Владелец (owner) ---

    async def get_outlet_orders(
        self, current_user: TokenData, filters: "OrderFilters", offset: int, limit: int
    ) -> OrderListResponse:
        from app.modules.orders.models import OrderStatus as ModelStatus
        status = ModelStatus(filters.status.value) if filters.status else None
        outlet_ids = await self._get_outlet_ids(current_user)
        orders, total = await self._orders.list_by_outlet_ids(
            outlet_ids,
            status=status,
            date_from=filters.date_from,
            date_to=filters.date_to,
            sort_by=filters.sort_by.value,
            sort_order=filters.sort_order.value,
            offset=offset,
            limit=limit,
        )
        return OrderListResponse(
            items=list(await asyncio.gather(*[self._to_response(o) for o in orders])),
            total=total,
        )

    async def owner_assemble(self, current_user: TokenData, order_id: int) -> OrderResponse:
        """assigned → assembling (доставка) или new → assembling (самовывоз)."""
        order = await self._get_owner_order(current_user, order_id)
        if order.delivery_type == DeliveryType.pickup:
            allowed = (OrderStatus.new,)
        else:
            allowed = (OrderStatus.assigned,)
        if order.status not in allowed:
            raise OrderInvalidStatusError(
                f"Заказ должен быть в статусе '{'new' if order.delivery_type == DeliveryType.pickup else 'assigned'}'"
            )

        updated = await self._orders.update_status(order, OrderStatus.assembling, current_user.user_id)
        await self._publish_status_event(updated)
        return await self._to_response(updated)

    async def owner_ready(self, current_user: TokenData, order_id: int) -> OrderResponse:
        """assembling → ready_for_pickup."""
        order = await self._get_owner_order(current_user, order_id)
        if order.status != OrderStatus.assembling:
            raise OrderInvalidStatusError("Заказ должен быть в статусе 'assembling'")

        updated = await self._orders.update_status(order, OrderStatus.ready_for_pickup, current_user.user_id)
        await self._publish_status_event(updated)
        return await self._to_response(updated)

    async def owner_cancel(self, current_user: TokenData, order_id: int) -> OrderResponse:
        order = await self._get_owner_order(current_user, order_id)
        if order.status in (OrderStatus.delivered, OrderStatus.received, OrderStatus.cancelled):
            raise OrderInvalidStatusError("Нельзя отменить завершённый заказ")

        await self._return_to_goden(order)
        updated = await self._orders.update_status(order, OrderStatus.cancelled, current_user.user_id)
        if updated.courier_id:
            await self._clear_courier_active_order(updated.courier_id)
        await self._publish_status_event(updated)
        return await self._to_response(updated)

    # --- Модератор ---

    async def admin_list_orders(
        self, filters: OrderFilters, offset: int, limit: int
    ) -> OrderListResponse:
        from app.modules.orders.models import OrderStatus as ModelStatus
        status = ModelStatus(filters.status.value) if filters.status else None
        orders, total = await self._orders.list_all(
            status=status,
            outlet_id=filters.outlet_id,
            outlet_ids=filters.outlet_ids,
            search=filters.search,
            date_from=filters.date_from,
            date_to=filters.date_to,
            sort_by=filters.sort_by.value,
            sort_order=filters.sort_order.value,
            offset=offset,
            limit=limit,
        )
        return OrderListResponse(
            items=list(await asyncio.gather(*[self._to_response(o) for o in orders])),
            total=total,
        )

    async def admin_assign(
        self, current_user: TokenData, order_id: int, courier_id: int
    ) -> OrderResponse:
        order = await self._orders.get_by_id(order_id)
        if not order:
            raise OrderNotFoundError()
        if order.status != OrderStatus.new:
            raise OrderInvalidStatusError("Ручное назначение возможно только для заказа в статусе 'new'")

        courier = await self._couriers.get_by_id(courier_id)
        if not courier:
            from app.modules.couriers.exceptions import CourierNotFoundError
            raise CourierNotFoundError()

        shift = await self._shifts.get_active(courier_id)
        if not shift:
            raise CourierNotOnShiftError()

        active = await self._orders.get_active_by_courier(courier_id)
        if active:
            raise CourierHasActiveOrderError()

        updated = await self._orders.assign_courier(order, courier_id, current_user.user_id)
        await self._set_courier_active_order(courier_id, order_id)

        await kafka.publish_event("courier.assigned", {
            "order_id": order_id,
            "courier_id": courier_id,
            "customer_id": order.customer_id,
            "outlet_id": order.outlet_id,
        })
        await self._publish_status_event(updated)
        return await self._to_response(updated)

    async def admin_cancel(self, current_user: TokenData, order_id: int) -> OrderResponse:
        order = await self._orders.get_by_id(order_id)
        if not order:
            raise OrderNotFoundError()
        if order.status in (OrderStatus.delivered, OrderStatus.received, OrderStatus.cancelled):
            raise OrderInvalidStatusError("Нельзя отменить завершённый заказ")

        await self._return_to_goden(order)
        updated = await self._orders.update_status(order, OrderStatus.cancelled, current_user.user_id)
        if updated.courier_id:
            await self._clear_courier_active_order(updated.courier_id)
        await self._publish_status_event(updated)
        return await self._to_response(updated)

    # --- Вспомогательные методы ---

    def _check_outlet_open(self, outlet: dict) -> None:
        import pytz
        from datetime import time as dtime

        tz_name = outlet.get("timezone", "UTC")
        try:
            tz = pytz.timezone(tz_name)
        except Exception:
            tz = pytz.utc

        now_local = datetime.now(tz).time()
        opens = outlet["opens_at"]
        closes = outlet["closes_at"]

        # SQLAlchemy возвращает time-объект
        if isinstance(opens, dtime) and isinstance(closes, dtime):
            if not (opens <= now_local <= closes):
                raise OutletClosedError()

    def _calc_delivery_fee(self, outlet: dict, distance_km: float) -> Decimal:
        """Сбор точки + платформенная надбавка за км сверх порога."""
        base = Decimal(str(outlet["delivery_fee"]))
        extra_km = max(0.0, distance_km - _FREE_DELIVERY_UP_TO_KM)
        return base + Decimal(str(round(extra_km, 2))) * _PRICE_PER_KM

    async def _resolve_delivery_address(self, data: OrderCreate):
        """Возвращает адрес доставки из книги адресов."""
        if not data.customer_address_id:
            raise DeliveryAddressRequiredError()
        address = await self._orders.get_address(data.customer_address_id)
        if not address:
            raise DeliveryAddressRequiredError()
        return address

    async def _check_payment_method(self, customer_id: int, method_id: int) -> None:
        from sqlalchemy import text
        # Проверяем через CatalogReadRepository что метод принадлежит покупателю
        result = await self._catalog._session.execute(
            text(
                "SELECT id FROM customer_payment_methods "
                "WHERE id = :id AND customer_id = :customer_id AND is_active = true"
            ),
            {"id": method_id, "customer_id": customer_id},
        )
        if not result.scalar_one_or_none():
            raise PaymentMethodNotFoundError()

    async def _get_courier_order(
        self, current_user: TokenData, order_id: int
    ) -> tuple:
        order = await self._orders.get_by_id(order_id)
        if not order:
            raise OrderNotFoundError()
        courier = await self._couriers.get_or_create(current_user.user_id)
        if order.courier_id != courier.id:
            raise OrderAccessDeniedError()
        return order, courier

    async def _get_outlet_ids(self, current_user: TokenData) -> list[int]:
        """Возвращает outlet_ids доступные текущему пользователю (owner или outlet_manager)."""
        if current_user.role == "outlet_manager":
            return await self._outlets.get_manager_outlet_ids(current_user.user_id)
        return await self._outlets.get_owner_outlet_ids(current_user.user_id)

    async def _get_owner_order(self, current_user: TokenData, order_id: int):
        order = await self._orders.get_by_id(order_id)
        if not order:
            raise OrderNotFoundError()
        outlet_ids = await self._get_outlet_ids(current_user)
        if order.outlet_id not in outlet_ids:
            raise OrderAccessDeniedError()
        return order

    async def _publish_status_event(self, order) -> None:
        # Получаем courier_user_id для маршрутизации в realtime_service
        courier_user_id = None
        if order.courier_id:
            courier = await self._couriers.get_by_id(order.courier_id)
            if courier:
                courier_user_id = courier.user_id

        await kafka.publish_event("order.status_updated", {
            "order_id": order.id,
            "status": order.status.value,
            "customer_id": order.customer_id,
            "outlet_id": order.outlet_id,
            "courier_id": order.courier_id,
            "courier_user_id": courier_user_id,
        })

    async def _set_courier_active_order(self, courier_id: int, order_id: int) -> None:
        key = f"courier:{courier_id}:state"
        raw = await self._redis.get(key)
        state = json.loads(raw) if raw else {}
        state["active_order_id"] = order_id
        await self._redis.setex(key, _COURIER_STATE_TTL, json.dumps(state))

    async def _clear_courier_active_order(self, courier_id: int) -> None:
        key = f"courier:{courier_id}:state"
        raw = await self._redis.get(key)
        if raw:
            state = json.loads(raw)
            state.pop("active_order_id", None)
            await self._redis.setex(key, _COURIER_STATE_TTL, json.dumps(state))

    async def _offer_order_to_next_courier(
        self, order_id: int, latitude: float, longitude: float
    ) -> None:
        """Найти ближайшего свободного курьера и предложить ему заказ на _OFFER_TTL_SEC секунд."""
        logger.info("Оффер запущен для заказа %s lat=%s lon=%s", order_id, latitude, longitude)
        # Список уже отказавшихся курьеров
        rejected_key = _OFFER_REJECTED_KEY.format(order_id=order_id)
        rejected_ids_raw = await self._redis.smembers(rejected_key)
        exclude_ids = [int(x) for x in rejected_ids_raw] if rejected_ids_raw else []

        courier = await self._couriers.find_nearest_free_courier(
            latitude=latitude,
            longitude=longitude,
            exclude_courier_ids=exclude_ids or None,
        )
        if not courier:
            logger.info("Нет доступных курьеров для заказа %s", order_id)
            return


        # Записываем оффер в Redis с TTL
        offer_key = _OFFER_KEY.format(order_id=order_id)
        await self._redis.setex(offer_key, _OFFER_TTL_SEC, str(courier.id))

        # Фиксируем оффер в БД (для страховки при рестарте воркера)
        order = await self._orders.get_by_id(order_id)
        if order:
            expires_at = datetime.now(timezone.utc) + timedelta(seconds=_OFFER_TTL_SEC)
            await self._orders.set_offer(order, courier.id, expires_at)

        # Собираем данные заказа для курьера
        address = await self._orders.get_address(order.customer_address_id) if order.customer_address_id else None
        outlet = await self._outlets.get_outlet(order.outlet_id)

        # Расстояние от ресторана до клиента
        distance_km = None
        if address and address.latitude and address.longitude:
            distance_km = await self._outlets.get_distance_km(
                order.outlet_id, float(address.latitude), float(address.longitude)
            )

        # Примерное время доставки (средняя скорость ~25 км/ч)
        estimated_minutes = round(distance_km / 25 * 60) if distance_km else None

        offer_payload = {
            "order_id": order_id,
            "courier_id": courier.id,
            "courier_user_id": courier.user_id,
            "expires_in": _OFFER_TTL_SEC,
            "outlet_id": order.outlet_id,
            "outlet_name": outlet.get("name", "") if outlet else "",
            "outlet_address": outlet.get("address", "") if outlet else "",
            "outlet_latitude": float(outlet["latitude"]) if outlet and outlet.get("latitude") else None,
            "outlet_longitude": float(outlet["longitude"]) if outlet and outlet.get("longitude") else None,
            "total_price": str(order.total_price),
            "delivery_address": address.address if address else "",
            "delivery_latitude": float(address.latitude) if address and address.latitude else None,
            "delivery_longitude": float(address.longitude) if address and address.longitude else None,
            "distance_km": round(distance_km, 1) if distance_km else None,
            "estimated_minutes": estimated_minutes,
            "items": [
                {"name": i.name, "quantity": i.quantity}
                for i in order.items
            ],
        }

        # Уведомляем курьера через Kafka → WebSocket
        # courier_user_id нужен realtime_service для маршрутизации по user_id
        await kafka.publish_event("courier.order_offer", offer_payload)
        logger.info("Заказ %s предложен курьеру %s (user_id=%s)", order_id, courier.id, courier.user_id)

    async def _get_full_response(self, order_id: int) -> OrderResponse:
        order = await self._orders.get_by_id(order_id)
        return await self._to_response(order)

    async def _to_response(self, order) -> OrderResponse:
        address = await self._orders.get_address(order.customer_address_id) if order.customer_address_id else None
        items = [
            OrderItemResponse(
                id=i.id,
                catalog_item_id=i.catalog_item_id,
                name=i.name,
                price=Decimal(str(i.price)),
                quantity=i.quantity,
                subtotal=Decimal(str(i.price)) * i.quantity,
            )
            for i in order.items
        ]
        history = [
            StatusHistoryResponse.model_validate(h)
            for h in sorted(order.status_history, key=lambda h: h.changed_at)
        ]
        delivery_address = AddressResponse.model_validate(address) if address else None
        return OrderResponse(
            id=order.id,
            customer_id=order.customer_id,
            company_id=order.company_id,
            outlet_id=order.outlet_id,
            courier_id=order.courier_id,
            status=order.status.value,
            delivery_type=order.delivery_type.value,
            delivery_address=delivery_address,
            total_price=Decimal(str(order.total_price)),
            comment=order.comment,
            customer_payment_method_id=order.customer_payment_method_id,
            delivery_time=order.delivery_time,
            leave_at_door=order.leave_at_door,
            created_at=order.created_at,
            updated_at=order.updated_at,
            items=items,
            status_history=history,
        )
