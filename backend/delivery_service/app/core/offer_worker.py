"""Фоновый воркер: предлагает курьерам новые заказы доставки без действующего оффера.

Оффер живёт _OFFER_TTL_SEC: если курьер не ответил, был не в сети или свободного курьера
не нашлось, заказ предлагается снова при следующем проходе, пока его не примут или не отменят.
"""
import asyncio
import logging

from redis.asyncio import Redis
from sqlalchemy import func, or_, select

from app.db.session import AsyncSessionFactory

logger = logging.getLogger(__name__)

_SWEEP_SEC = 5


async def watch_expired_offers(redis: Redis) -> None:
    """Запускается один раз при старте приложения как asyncio-задача."""
    from app.modules.orders.models import DeliveryType, Order, OrderStatus

    while True:
        await asyncio.sleep(_SWEEP_SEC)
        try:
            async with AsyncSessionFactory() as session:
                order_ids = (await session.execute(
                    select(Order.id).where(
                        Order.status == OrderStatus.new,
                        Order.delivery_type == DeliveryType.delivery,
                        or_(Order.offer_expires_at.is_(None), Order.offer_expires_at < func.now()),
                    )
                )).scalars().all()
            for order_id in order_ids:
                await _handle_expired_offer(redis, order_id)
        except asyncio.CancelledError:
            raise
        except Exception:
            # воркер не должен умирать от ошибки одного прохода
            logger.exception("offer_worker: ошибка прохода")


async def _handle_expired_offer(redis: Redis, order_id: int) -> None:
    """Сбрасываем оффер в БД и предлагаем заказ следующему курьеру."""
    from app.modules.orders.repository import OrderRepository, OutletReadRepository
    from app.modules.couriers.repository import CourierRepository
    from app.modules.shifts.repository import ShiftRepository
    from app.modules.orders.service import OrderService

    async with AsyncSessionFactory() as session:
        order_repo = OrderRepository(session)
        order = await order_repo.get_by_id(order_id)

        if not order:
            return
        if order.status.value != "new":
            # Заказ уже принят или отменён - ничего не делаем
            return

        # Сбрасываем оффер в БД
        await order_repo.clear_offer(order)
        await session.commit()

        # Переиспользуем сервис для поиска следующего курьера
        service = OrderService(
            order_repo=order_repo,
            outlet_repo=OutletReadRepository(session),  # точка нужна для данных оффера
            cart_repo=None,
            catalog_repo=None,
            courier_repo=CourierRepository(session),
            shift_repo=ShiftRepository(session),
            redis=redis,
        )

        address = await order_repo.get_address(order.customer_address_id) if order.customer_address_id else None
        if address and address.latitude and address.longitude:
            await service._offer_order_to_next_courier(
                order_id, float(address.latitude), float(address.longitude)
            )
            await session.commit()
