"""Позиция курьера: состояние в Redis сохраняется, событие называет покупателя активного заказа."""
import asyncio
import json
from types import SimpleNamespace

from app.core import kafka
from app.modules.couriers.schemas import LocationUpdate
from app.modules.couriers.service import CourierService

COURIER = SimpleNamespace(id=5, is_blocked=False)


class FakeCouriers:
    async def get_or_create(self, user_id):
        return COURIER

    async def update_location(self, courier, latitude, longitude):
        pass


class FakeRedis:
    def __init__(self, state):
        self.data = {"courier:5:state": json.dumps(state)}

    async def get(self, key):
        return self.data.get(key)

    async def setex(self, key, ttl, value):
        self.data[key] = value


class FakeOrders:
    def __init__(self, order):
        self.order = order

    async def get_active_by_courier(self, courier_id):
        assert courier_id == COURIER.id
        return self.order


def _move(monkeypatch, order):
    events = []

    async def publish(topic, payload):
        events.append((topic, payload))

    monkeypatch.setattr(kafka, "publish_event", publish)
    redis = FakeRedis({"courier_id": 5, "is_online": True, "active_order_id": 42})
    service = CourierService(FakeCouriers(), redis, FakeOrders(order))
    user = SimpleNamespace(user_id=11)
    asyncio.run(service.update_location(user, LocationUpdate(latitude=55.75, longitude=37.62)))
    return events, json.loads(redis.data["courier:5:state"])


def test_location_reaches_customer_of_active_order(monkeypatch):
    events, state = _move(monkeypatch, SimpleNamespace(id=42, customer_id=7))
    topic, payload = events[0]
    assert topic == "courier.location_updated"
    assert (payload["customer_id"], payload["order_id"]) == (7, 42)
    # координаты дописаны, признаки смены и заказа сохранились
    assert state == {"courier_id": 5, "is_online": True, "active_order_id": 42, "latitude": 55.75, "longitude": 37.62}


def test_location_without_order_has_no_customer(monkeypatch):
    events, _ = _move(monkeypatch, None)
    assert "customer_id" not in events[0][1]
