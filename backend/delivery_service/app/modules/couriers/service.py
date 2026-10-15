import json
import logging

from redis.asyncio import Redis

from app.core import kafka
from app.core.dependencies import TokenData
from app.modules.couriers.exceptions import (
    CourierAlreadyBlockedError,
    CourierAlreadyUnblockedError,
    CourierBlockedError,
    CourierNotFoundError,
)
from app.modules.couriers.repository import CourierRepository
from app.modules.orders.repository import OrderRepository
from app.modules.couriers.schemas import (
    CourierListResponse,
    CourierProfileUpdate,
    CourierResponse,
    LocationUpdate,
)

logger = logging.getLogger(__name__)

_COURIER_STATE_TTL = 1800  # 30 минут


def _courier_state_key(courier_id: int) -> str:
    return f"courier:{courier_id}:state"


class CourierService:
    def __init__(self, repo: CourierRepository, redis: Redis, orders: OrderRepository) -> None:
        self._repo = repo
        self._redis = redis
        # заказы нужны для позиции курьера: событие называет покупателя его заказа
        self._orders = orders

    async def get_my_profile(self, current_user: TokenData) -> CourierResponse:
        """Возвращает профиль курьера. Создаёт запись если не существует (lazy init)."""
        courier = await self._repo.get_or_create(current_user.user_id)
        return self._to_response(courier)

    async def update_profile(self, current_user: TokenData, data: CourierProfileUpdate) -> CourierResponse:
        courier = await self._repo.get_or_create(current_user.user_id)
        if data.type_movement is not None:
            courier.type_movement = data.type_movement
        if data.radius_km is not None:
            courier.radius_km = data.radius_km
        if data.zone_latitude is not None:
            courier.zone_latitude = data.zone_latitude
        if data.zone_longitude is not None:
            courier.zone_longitude = data.zone_longitude
        await self._repo._session.flush()
        return self._to_response(courier)

    async def get_by_id(self, courier_id: int) -> CourierResponse:
        courier = await self._repo.get_by_id(courier_id)
        if not courier:
            raise CourierNotFoundError()
        return self._to_response(courier)

    async def list_couriers(self, offset: int, limit: int) -> CourierListResponse:
        couriers, total = await self._repo.list_all(offset=offset, limit=limit)
        return CourierListResponse(
            items=[self._to_response(c) for c in couriers],
            total=total,
        )

    async def block(self, courier_id: int) -> CourierResponse:
        courier = await self._repo.get_by_id(courier_id)
        if not courier:
            raise CourierNotFoundError()
        if courier.is_blocked:
            raise CourierAlreadyBlockedError()
        updated = await self._repo.set_blocked(courier, blocked=True)
        return self._to_response(updated)

    async def unblock(self, courier_id: int) -> CourierResponse:
        courier = await self._repo.get_by_id(courier_id)
        if not courier:
            raise CourierNotFoundError()
        if not courier.is_blocked:
            raise CourierAlreadyUnblockedError()
        updated = await self._repo.set_blocked(courier, blocked=False)
        return self._to_response(updated)

    async def update_location(self, current_user: TokenData, data: LocationUpdate) -> dict:
        courier = await self._repo.get_or_create(current_user.user_id)
        if courier.is_blocked:
            raise CourierBlockedError()

        await self._repo.update_location(courier, data.latitude, data.longitude)

        # в состоянии курьера лежат и признаки смены и заказа: координаты дописываются, а не заменяют их
        key = _courier_state_key(courier.id)
        raw = await self._redis.get(key)
        state = json.loads(raw) if raw else {}
        state.update(courier_id=courier.id, latitude=data.latitude, longitude=data.longitude)
        await self._redis.setex(key, _COURIER_STATE_TTL, json.dumps(state))

        event = {
            "courier_id": courier.id,
            "user_id": current_user.user_id,
            "latitude": data.latitude,
            "longitude": data.longitude,
        }
        # realtime отправляет позицию покупателю активного заказа курьера
        order = await self._orders.get_active_by_courier(courier.id)
        if order:
            event.update(order_id=order.id, customer_id=order.customer_id)
        await kafka.publish_event("courier.location_updated", event)

        return {"status": "ok", "latitude": data.latitude, "longitude": data.longitude}

    def _to_response(self, courier) -> CourierResponse:
        return CourierResponse(
            id=courier.id,
            user_id=courier.user_id,
            is_blocked=courier.is_blocked,
            type_movement=courier.type_movement,
            radius_km=courier.radius_km,
            zone_latitude=float(courier.zone_latitude) if courier.zone_latitude else None,
            zone_longitude=float(courier.zone_longitude) if courier.zone_longitude else None,
            current_latitude=float(courier.current_latitude) if courier.current_latitude else None,
            current_longitude=float(courier.current_longitude) if courier.current_longitude else None,
            location_updated_at=courier.location_updated_at,
        )
