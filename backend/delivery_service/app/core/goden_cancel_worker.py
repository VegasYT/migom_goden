"""Фоновый воркер: заказы, которые отменил сотрудник точки Goden, отменяются и в Мигоме.

Goden сам Мигому не сообщает: воркер раз в _SWEEP_SEC читает в Goden незавершённые заказы Мигома.
Пропущенная отмена (Goden недоступен) дойдёт следующим проходом.
"""
import asyncio
import logging
import uuid
from collections.abc import Awaitable, Callable

from redis.asyncio import Redis
from sqlalchemy import select

from app.core import goden
from app.db.session import AsyncSessionFactory
from app.modules.orders.models import FINISHED, Order, OrderStatus

logger = logging.getLogger(__name__)

_SWEEP_SEC = 15
DEFAULT_REASON = "Отменён рестораном"


def cancellation(status: OrderStatus, goden_order: dict) -> str | None:
    """Причина отмены заказа Мигома по его заказу Goden; None - отменять не нужно."""
    if status in FINISHED or goden_order.get("status") != "cancelled":
        return None
    return (goden_order.get("cancel_comment") or "").strip() or DEFAULT_REASON


async def check(
    orders: list[tuple[int, OrderStatus, uuid.UUID, uuid.UUID]],
    read: Callable[[uuid.UUID, uuid.UUID], Awaitable[dict]],
    cancel: Callable[[int, str], Awaitable[None]],
) -> None:
    """Сверяет заказы (id, статус, точка и заказ Goden) с Goden. Недоступный Goden прерывает проход."""
    for order_id, status, point_id, goden_order_id in orders:
        try:
            goden_order = await read(point_id, goden_order_id)
        except goden.GodenRefusedError as e:
            # заведение отключили или точку выключили: Goden заказ Мигому больше не отдаёт
            logger.debug("Заказ Goden %s для заказа %s не прочитан: %s", goden_order_id, order_id, e)
            continue
        reason = cancellation(status, goden_order)
        if reason:
            await cancel(order_id, reason)


async def watch_goden_cancellations(redis: Redis) -> None:
    """Запускается один раз при старте приложения как asyncio-задача."""
    while True:
        await asyncio.sleep(_SWEEP_SEC)
        try:
            async with AsyncSessionFactory() as session:
                orders = (await session.execute(
                    select(Order.id, Order.status, Order.goden_point_id, Order.goden_order_id).where(
                        Order.goden_order_id.is_not(None), Order.status.not_in(FINISHED),
                    )
                )).all()
            await check([tuple(o) for o in orders], goden.order, lambda order_id, reason: _cancel(redis, order_id, reason))
        except asyncio.CancelledError:
            raise
        except goden.GodenUnavailableError:
            logger.warning("goden_cancel_worker: Goden недоступен, проход повторится")
        except Exception:
            # воркер не должен умирать от ошибки одного прохода
            logger.exception("goden_cancel_worker: ошибка прохода")


async def _cancel(redis: Redis, order_id: int, reason: str) -> None:
    from app.modules.couriers.repository import CourierRepository
    from app.modules.orders.repository import OrderRepository
    from app.modules.orders.service import OrderService

    async with AsyncSessionFactory() as session:
        service = OrderService(
            order_repo=OrderRepository(session),
            outlet_repo=None,
            cart_repo=None,
            catalog_repo=None,
            courier_repo=CourierRepository(session),  # курьер нужен событию статуса
            shift_repo=None,
            redis=redis,
        )
        if await service.cancel_from_goden(order_id, reason):
            await session.commit()
            logger.info("Заказ %s отменён сотрудником точки Goden: %s", order_id, reason)
