from typing import Annotated

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import TokenData, get_current_user, require_roles
from app.db.session import get_db
from app.modules.couriers.repository import CourierRepository
from app.modules.shifts.repository import ShiftRepository
from app.modules.shifts.schemas import ActiveShiftsResponse, ShiftListResponse, ShiftResponse
from app.modules.shifts.service import ShiftService

router = APIRouter(tags=["Смены курьеров"])


def _get_service(request: Request, session: Annotated[AsyncSession, Depends(get_db)]) -> ShiftService:
    return ShiftService(
        shift_repo=ShiftRepository(session),
        courier_repo=CourierRepository(session),
        redis=request.app.state.redis,
    )


@router.post("/shifts/start", response_model=ShiftResponse, status_code=201)
async def start_shift(
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[ShiftService, Depends(_get_service)],
):
    """Начать рабочую смену. Нельзя открыть вторую смену пока активна первая."""
    return await service.start_shift(current_user)


@router.post("/shifts/end", response_model=ShiftResponse)
async def end_shift(
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[ShiftService, Depends(_get_service)],
):
    """Завершить активную смену. Нельзя завершить если есть активный заказ."""
    return await service.end_shift(current_user)


@router.get("/shifts/me/current", response_model=ShiftResponse)
async def get_current_shift(
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[ShiftService, Depends(_get_service)],
):
    """Текущая активная смена курьера."""
    return await service.get_current(current_user)


@router.get("/shifts/me/history", response_model=ShiftListResponse)
async def get_shift_history(
    offset: int = 0,
    limit: int = 20,
    current_user: Annotated[TokenData, Depends(require_roles("courier"))] = None,
    service: Annotated[ShiftService, Depends(_get_service)] = None,
):
    """История смен текущего курьера."""
    return await service.get_history(current_user, offset=offset, limit=limit)


@router.get("/shifts", response_model=ActiveShiftsResponse)
async def list_active_shifts(
    offset: int = 0,
    limit: int = 20,
    _: Annotated[TokenData, Depends(require_roles("moderator"))] = None,
    service: Annotated[ShiftService, Depends(_get_service)] = None,
):
    """Все активные смены (онлайн-курьеры). Только модератор."""
    return await service.list_active_all(offset=offset, limit=limit)
