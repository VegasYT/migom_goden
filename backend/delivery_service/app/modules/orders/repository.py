from datetime import datetime, timezone

from sqlalchemy import and_, select, func, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.orders.models import DeliveryType, Order, OrderItem, OrderStatus, OrderStatusHistory


class OrderRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, order_id: int) -> Order | None:
        result = await self._session.execute(
            select(Order)
            .options(
                selectinload(Order.items),
                selectinload(Order.status_history),
            )
            .where(Order.id == order_id)
        )
        return result.scalar_one_or_none()

    async def list_by_customer(
        self, customer_id: int, offset: int = 0, limit: int = 20
    ) -> tuple[list[Order], int]:
        total = await self._session.scalar(
            select(func.count(Order.id)).where(Order.customer_id == customer_id)
        )
        result = await self._session.execute(
            select(Order)
            .options(selectinload(Order.items), selectinload(Order.status_history))
            .where(Order.customer_id == customer_id)
            .order_by(Order.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(result.scalars().all()), total or 0

    async def list_by_outlet_ids(
        self,
        outlet_ids: list[int],
        status: OrderStatus | None = None,
        date_from: datetime | None = None,
        date_to: datetime | None = None,
        sort_by: str = "created_at",
        sort_order: str = "desc",
        offset: int = 0,
        limit: int = 20,
    ) -> tuple[list[Order], int]:
        """Заказы для владельца/менеджера - по его точкам."""
        conditions = [Order.outlet_id.in_(outlet_ids)]

        if status:
            conditions.append(Order.status == status)
        if date_from:
            conditions.append(Order.created_at >= date_from)
        if date_to:
            conditions.append(Order.created_at <= date_to)

        where_clause = and_(*conditions)

        sort_col = Order.total_price if sort_by == "total_price" else Order.created_at
        order_clause = sort_col.asc() if sort_order == "asc" else sort_col.desc()

        total = await self._session.scalar(
            select(func.count(Order.id)).where(where_clause)
        )
        result = await self._session.execute(
            select(Order)
            .options(selectinload(Order.items), selectinload(Order.status_history))
            .where(where_clause)
            .order_by(order_clause)
            .offset(offset)
            .limit(limit)
        )
        return list(result.scalars().all()), total or 0

    async def list_all(
        self,
        status: OrderStatus | None = None,
        outlet_id: int | None = None,
        outlet_ids: list[int] | None = None,
        search: str | None = None,
        date_from: datetime | None = None,
        date_to: datetime | None = None,
        sort_by: str = "created_at",
        sort_order: str = "desc",
        offset: int = 0,
        limit: int = 20,
    ) -> tuple[list[Order], int]:
        """Все заказы с фильтрами - для модератора."""
        conditions = []
        if status:
            conditions.append(Order.status == status)
        if outlet_ids:
            conditions.append(Order.outlet_id.in_(outlet_ids))
        elif outlet_id:
            conditions.append(Order.outlet_id == outlet_id)
        if date_from:
            conditions.append(Order.created_at >= date_from)
        if date_to:
            conditions.append(Order.created_at <= date_to)
        if search:
            # Поиск по числовому ID или по комментарию
            try:
                search_id = int(search)
                conditions.append(Order.id == search_id)
            except ValueError:
                conditions.append(Order.comment.ilike(f"%{search}%"))

        where_clause = and_(*conditions) if conditions else True

        sort_col = Order.total_price if sort_by == "total_price" else (
            Order.id if sort_by == "id" else Order.created_at
        )
        order_clause = sort_col.asc() if sort_order == "asc" else sort_col.desc()

        total = await self._session.scalar(
            select(func.count(Order.id)).where(where_clause)
        )
        result = await self._session.execute(
            select(Order)
            .options(selectinload(Order.items), selectinload(Order.status_history))
            .where(where_clause)
            .order_by(order_clause)
            .offset(offset)
            .limit(limit)
        )
        return list(result.scalars().all()), total or 0

    async def get_active_by_courier(self, courier_id: int) -> Order | None:
        """Текущий активный заказ курьера."""
        result = await self._session.execute(
            select(Order)
            .options(selectinload(Order.items), selectinload(Order.status_history))
            .where(
                Order.courier_id == courier_id,
                Order.status.in_([OrderStatus.assigned, OrderStatus.in_delivery]),
            )
        )
        return result.scalar_one_or_none()

    async def list_available_for_courier(self, courier_id: int) -> list[Order]:
        """Заказы в статусе new с delivery_type=delivery, адрес которых в радиусе курьера.

        Центр радиуса: zone_latitude/longitude если заданы, иначе текущая позиция.
        """
        from app.modules.couriers.models import Courier
        from app.modules.customers.models import CustomerAddress

        courier = await self._session.get(Courier, courier_id)
        if not courier:
            return []

        # Центр зоны поиска: заданная точка или текущая позиция
        center_lat = courier.zone_latitude or courier.current_latitude
        center_lon = courier.zone_longitude or courier.current_longitude
        if not center_lat or not center_lon:
            return []

        result = await self._session.execute(
            select(Order)
            .options(selectinload(Order.items))
            .join(CustomerAddress, CustomerAddress.id == Order.customer_address_id)
            .where(
                Order.status == OrderStatus.new,
                Order.delivery_type == DeliveryType.delivery,
                Order.customer_address_id.is_not(None),
                CustomerAddress.latitude.is_not(None),
                CustomerAddress.longitude.is_not(None),
                text(
                    "ST_DWithin("
                    "  ST_MakePoint(:c_lon, :c_lat)::geography,"
                    "  ST_MakePoint(customer_addresses.longitude::float, customer_addresses.latitude::float)::geography,"
                    "  :radius_m"
                    ")"
                ).bindparams(
                    c_lat=float(center_lat),
                    c_lon=float(center_lon),
                    radius_m=courier.radius_km * 1000,
                ),
            )
        )
        return list(result.scalars().all())

    async def get_address(self, address_id: int):
        """Получить адрес по ID."""
        from app.modules.customers.models import CustomerAddress
        result = await self._session.execute(
            select(CustomerAddress).where(CustomerAddress.id == address_id)
        )
        return result.scalar_one_or_none()

    async def create(
        self,
        customer_id: int,
        company_id: int,
        outlet_id: int,
        delivery_type: DeliveryType,
        customer_payment_method_id: int,
        total_price: float,
        customer_address_id: int | None,
        comment: str | None,
        leave_at_door: bool,
    ) -> Order:
        order = Order(
            customer_id=customer_id,
            company_id=company_id,
            outlet_id=outlet_id,
            delivery_type=delivery_type,
            customer_payment_method_id=customer_payment_method_id,
            total_price=total_price,
            status=OrderStatus.new,
            customer_address_id=customer_address_id,
            comment=comment,
            leave_at_door=leave_at_door,
        )
        self._session.add(order)
        await self._session.flush()
        return order

    async def add_items(self, order_id: int, items: list[dict]) -> None:
        """items - список {catalog_item_id, name, price, quantity}."""
        for item in items:
            self._session.add(OrderItem(order_id=order_id, **item))
        await self._session.flush()

    async def add_status_history(
        self, order_id: int, status: OrderStatus, changed_by: int
    ) -> None:
        self._session.add(OrderStatusHistory(
            order_id=order_id,
            status=status.value,
            changed_by=changed_by,
        ))
        await self._session.flush()

    async def update_status(
        self, order: Order, status: OrderStatus, changed_by: int
    ) -> Order:
        order.status = status
        order.updated_at = datetime.now(timezone.utc)
        await self._session.flush()
        await self.add_status_history(order.id, status, changed_by)
        return order

    async def set_offer(
        self, order: Order, courier_id: int, expires_at: datetime
    ) -> Order:
        """Записать оффер: кому предложен заказ и до какого времени."""
        order.offered_courier_id = courier_id
        order.offer_expires_at = expires_at
        await self._session.flush()
        return order

    async def clear_offer(self, order: Order) -> Order:
        """Сбросить оффер после принятия/отказа/истечения."""
        order.offered_courier_id = None
        order.offer_expires_at = None
        await self._session.flush()
        return order

    async def get_new_delivery_orders_without_offer(self) -> list[Order]:
        """Заказы в статусе new без активного оффера - для переотправки после истечения."""
        result = await self._session.execute(
            select(Order)
            .options(selectinload(Order.items), selectinload(Order.status_history))
            .where(
                Order.status == OrderStatus.new,
                Order.delivery_type == DeliveryType.delivery,
                Order.offered_courier_id.is_(None),
            )
        )
        return list(result.scalars().all())

    async def assign_courier(
        self, order: Order, courier_id: int, changed_by: int
    ) -> Order:
        order.courier_id = courier_id
        order.status = OrderStatus.assigned
        order.updated_at = datetime.now(timezone.utc)
        await self._session.flush()
        await self.add_status_history(order.id, OrderStatus.assigned, changed_by)
        return order


class OutletReadRepository:
    """Read-only доступ к outlets и delivery_zones из единой БД."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_outlet(self, outlet_id: int) -> dict | None:
        result = await self._session.execute(
            text(
                "SELECT id, company_id, name, address, is_active, min_order_price, delivery_fee, "
                "opens_at, closes_at, timezone, latitude, longitude "
                "FROM outlets WHERE id = :id"
            ),
            {"id": outlet_id},
        )
        row = result.mappings().one_or_none()
        return dict(row) if row else None

    async def get_owner_outlet_ids(self, owner_id: int) -> list[int]:
        """Возвращает ID всех точек компаний владельца."""
        result = await self._session.execute(
            text(
                "SELECT o.id FROM outlets o "
                "JOIN companies c ON c.id = o.company_id "
                "WHERE c.owner_id = :owner_id AND o.is_active = true"
            ),
            {"owner_id": owner_id},
        )
        return [row[0] for row in result.fetchall()]

    async def get_manager_outlet_ids(self, user_id: int) -> list[int]:
        """Возвращает ID точек на которых назначен менеджер."""
        result = await self._session.execute(
            text(
                "SELECT om.outlet_id FROM outlet_managers om "
                "JOIN outlets o ON o.id = om.outlet_id "
                "WHERE om.user_id = :user_id AND o.is_active = true"
            ),
            {"user_id": user_id},
        )
        return [row[0] for row in result.fetchall()]

    async def get_distance_km(
        self, outlet_id: int, latitude: float, longitude: float
    ) -> float | None:
        """Возвращает расстояние в км от точки до адреса клиента через PostGIS."""
        result = await self._session.execute(
            text(
                "SELECT ST_Distance("
                "  ST_MakePoint(longitude::float, latitude::float)::geography,"
                "  ST_MakePoint(:lon, :lat)::geography"
                ") / 1000.0 FROM outlets WHERE id = :outlet_id"
            ),
            {"outlet_id": outlet_id, "lon": longitude, "lat": latitude},
        )
        return result.scalar_one_or_none()

