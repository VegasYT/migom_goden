"""Фоновый воркер: слушает Redis keyspace events на истечение offer:{order_id}.

Когда TTL оффера истекает - курьер не ответил вовремя.
Воркер предлагает заказ следующему доступному курьеру.
"""
import asyncio
import logging

from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import AsyncSessionFactory

logger = logging.getLogger(__name__)

_OFFER_KEY_PREFIX = b"offer:"
_OFFER_REJECTED_SUFFIX = b":rejected"


async def watch_expired_offers(redis: Redis) -> None:
    """Запускается один раз при старте приложения как asyncio-задача."""
    # Отдельный pubsub-клиент (не разделяем с основным redis)
    pubsub = redis.pubsub()
    await pubsub.subscribe("__keyevent@1__:expired")
    logger.info("offer_worker: подписался на Redis keyspace events")

    try:
        async for message in pubsub.listen():
            if message["type"] != "message":
                continue
            key: bytes = message["data"]

            # Нас интересуют только offer:{order_id}, но не offer:{order_id}:rejected
            if not key.startswith(_OFFER_KEY_PREFIX):
                continue
            if key.endswith(_OFFER_REJECTED_SUFFIX):
                continue

            try:
                order_id = int(key[len(_OFFER_KEY_PREFIX):])
            except ValueError:
                continue

            logger.info("offer_worker: оффер для заказа %s истёк, ищем следующего курьера", order_id)
            asyncio.create_task(_handle_expired_offer(redis, order_id))

    except asyncio.CancelledError:
        logger.info("offer_worker: остановлен")
    finally:
        await pubsub.unsubscribe()


async def _handle_expired_offer(redis: Redis, order_id: int) -> None:
    """Сбрасываем оффер в БД и предлагаем заказ следующему курьеру."""
    from app.modules.orders.repository import OrderRepository
    from app.modules.couriers.repository import CourierRepository
    from app.modules.shifts.repository import ShiftRepository
    from app.modules.cart.repository import CartRepository, CatalogReadRepository
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
            outlet_repo=None,   # не нужен для этой операции
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
