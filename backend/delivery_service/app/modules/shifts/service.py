import json
import logging

from redis.asyncio import Redis

from app.core.dependencies import TokenData
from app.modules.couriers.exceptions import CourierBlockedError
from app.modules.couriers.repository import CourierRepository
from app.modules.shifts.exceptions import (
    CannotEndShiftWithActiveOrderError,
    NoActiveShiftError,
    ShiftAlreadyActiveError,
)
from app.modules.shifts.repository import ShiftRepository
from app.modules.shifts.schemas import ActiveShiftsResponse, ShiftListResponse, ShiftResponse

logger = logging.getLogger(__name__)

_COURIER_STATE_TTL = 1800  # 30 минут


def _courier_state_key(courier_id: int) -> str:
    return f"courier:{courier_id}:state"


class ShiftService:
    def __init__(
        self,
        shift_repo: ShiftRepository,
        courier_repo: CourierRepository,
        redis: Redis,
    ) -> None:
        self._shifts = shift_repo
        self._couriers = courier_repo
        self._redis = redis

    async def start_shift(self, current_user: TokenData) -> ShiftResponse:
        courier = await self._couriers.get_or_create(current_user.user_id)
        if courier.is_blocked:
            raise CourierBlockedError()

        existing = await self._shifts.get_active(courier.id)
        if existing:
            raise ShiftAlreadyActiveError()

        shift = await self._shifts.create(courier.id)

        # Помечаем курьера онлайн в Redis
        await self._set_online_state(courier.id, is_online=True)

        logger.info("Курьер %d начал смену %d", courier.id, shift.id)
        return ShiftResponse.model_validate(shift)

    async def end_shift(self, current_user: TokenData) -> ShiftResponse:
        courier = await self._couriers.get_or_create(current_user.user_id)

        shift = await self._shifts.get_active(courier.id)
        if not shift:
            raise NoActiveShiftError()

        # Проверяем отсутствие активного заказа через Redis-состояние
        await self._check_no_active_order(courier.id)

        shift = await self._shifts.end(shift)

        # Помечаем курьера офлайн в Redis
        await self._set_online_state(courier.id, is_online=False)

        logger.info("Курьер %d завершил смену %d", courier.id, shift.id)
        return ShiftResponse.model_validate(shift)

    async def get_current(self, current_user: TokenData) -> ShiftResponse:
        courier = await self._couriers.get_or_create(current_user.user_id)
        shift = await self._shifts.get_active(courier.id)
        if not shift:
            raise NoActiveShiftError()
        return ShiftResponse.model_validate(shift)

    async def get_history(
        self, current_user: TokenData, offset: int, limit: int
    ) -> ShiftListResponse:
        courier = await self._couriers.get_or_create(current_user.user_id)
        shifts, total = await self._shifts.list_by_courier(courier.id, offset=offset, limit=limit)
        return ShiftListResponse(
            items=[ShiftResponse.model_validate(s) for s in shifts],
            total=total,
        )

    async def list_active_all(self, offset: int, limit: int) -> ActiveShiftsResponse:
        """Все активные смены - для модератора."""
        shifts, total = await self._shifts.list_active_all(offset=offset, limit=limit)
        return ActiveShiftsResponse(
            items=[ShiftResponse.model_validate(s) for s in shifts],
            total=total,
        )

    async def _set_online_state(self, courier_id: int, is_online: bool) -> None:
        key = _courier_state_key(courier_id)
        raw = await self._redis.get(key)
        state = json.loads(raw) if raw else {}
        state["is_online"] = is_online
        state["courier_id"] = courier_id
        await self._redis.setex(key, _COURIER_STATE_TTL, json.dumps(state))

    async def _check_no_active_order(self, courier_id: int) -> None:
        """Проверяет через Redis что у курьера нет активного заказа."""
        key = _courier_state_key(courier_id)
        raw = await self._redis.get(key)
        if raw:
            state = json.loads(raw)
            if state.get("active_order_id"):
                raise CannotEndShiftWithActiveOrderError()
