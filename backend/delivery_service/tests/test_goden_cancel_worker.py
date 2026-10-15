"""Сверка заказов Мигома с Goden без базы и сети: чтение и отмена подменены."""
import asyncio
import uuid

import pytest

from app.core import goden
from app.core.goden_cancel_worker import DEFAULT_REASON, cancellation, check
from app.modules.orders.models import OrderStatus

POINT = uuid.UUID("0198c0de-0000-7000-8000-000000000012")


@pytest.mark.parametrize("status, goden_order, reason", [
    (OrderStatus.new, {"status": "cancelled", "cancel_comment": "нет курицы"}, "нет курицы"),
    (OrderStatus.in_delivery, {"status": "cancelled"}, DEFAULT_REASON),
    (OrderStatus.assembling, {"status": "cancelled", "cancel_comment": "  "}, DEFAULT_REASON),
    (OrderStatus.new, {"status": "accepted"}, None),
    (OrderStatus.delivered, {"status": "cancelled"}, None),
    (OrderStatus.received, {"status": "cancelled"}, None),
    (OrderStatus.cancelled, {"status": "cancelled"}, None),
])
def test_cancellation(status, goden_order, reason):
    assert cancellation(status, goden_order) == reason


def test_check_skips_refused_and_cancels_the_rest():
    refused, cancelled_in_goden, accepted = (uuid.uuid4() for _ in range(3))
    answers = {cancelled_in_goden: {"status": "cancelled", "cancel_comment": "нет курицы"}, accepted: {"status": "accepted"}}

    async def read(point_id, order_id):
        if order_id == refused:
            raise goden.GodenRefusedError(403)
        return answers[order_id]

    cancelled = []

    async def cancel(order_id, reason):
        cancelled.append((order_id, reason))

    orders = [(1, OrderStatus.new, POINT, refused), (2, OrderStatus.assigned, POINT, cancelled_in_goden),
              (3, OrderStatus.new, POINT, accepted)]
    asyncio.run(check(orders, read, cancel))
    assert cancelled == [(2, "нет курицы")]


def test_unavailable_goden_stops_the_pass():
    async def read(point_id, order_id):
        raise goden.GodenUnavailableError()

    async def cancel(order_id, reason):
        raise AssertionError("nothing is cancelled while Goden is unavailable")

    with pytest.raises(goden.GodenUnavailableError):
        asyncio.run(check([(1, OrderStatus.new, POINT, uuid.uuid4())], read, cancel))
