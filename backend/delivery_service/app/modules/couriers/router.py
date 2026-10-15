from typing import Annotated

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import TokenData, get_current_user, require_roles
from app.db.session import get_db
from app.modules.couriers.repository import CourierRepository
from app.modules.couriers.schemas import (
    CourierListResponse,
    CourierProfileUpdate,
    CourierResponse,
    LocationUpdate,
)
from app.modules.couriers.service import CourierService
from app.modules.orders.repository import OrderRepository

router = APIRouter(tags=["Курьеры"])


def _get_service(request: Request, session: Annotated[AsyncSession, Depends(get_db)]) -> CourierService:
    return CourierService(
        repo=CourierRepository(session),
        redis=request.app.state.redis,
        orders=OrderRepository(session),
    )


# --- Профиль курьера ---

@router.get("/couriers/me", response_model=CourierResponse)
async def get_my_profile(
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[CourierService, Depends(_get_service)],
):
    """Профиль текущего курьера. Создаётся автоматически при первом обращении."""
    return await service.get_my_profile(current_user)


@router.patch("/couriers/me", response_model=CourierResponse)
async def update_my_profile(
    data: CourierProfileUpdate,
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[CourierService, Depends(_get_service)],
):
    """Обновить профиль: тип передвижения (walk|scooter|car) и радиус поиска заказов в км."""
    return await service.update_profile(current_user, data)


@router.get("/couriers", response_model=CourierListResponse)
async def list_couriers(
    offset: int = 0,
    limit: int = 20,
    _: Annotated[TokenData, Depends(require_roles("moderator"))] = None,
    service: Annotated[CourierService, Depends(_get_service)] = None,
):
    """Список всех курьеров. Только модератор."""
    return await service.list_couriers(offset=offset, limit=limit)


@router.get("/couriers/{courier_id}", response_model=CourierResponse)
async def get_courier(
    courier_id: int,
    _: Annotated[TokenData, Depends(require_roles("moderator"))] = None,
    service: Annotated[CourierService, Depends(_get_service)] = None,
):
    """Профиль курьера по ID. Только модератор."""
    return await service.get_by_id(courier_id)


@router.post("/couriers/{courier_id}/block", response_model=CourierResponse)
async def block_courier(
    courier_id: int,
    _: Annotated[TokenData, Depends(require_roles("moderator"))] = None,
    service: Annotated[CourierService, Depends(_get_service)] = None,
):
    """Заблокировать курьера. Только модератор."""
    return await service.block(courier_id)


@router.post("/couriers/{courier_id}/unblock", response_model=CourierResponse)
async def unblock_courier(
    courier_id: int,
    _: Annotated[TokenData, Depends(require_roles("moderator"))] = None,
    service: Annotated[CourierService, Depends(_get_service)] = None,
):
    """Разблокировать курьера. Только модератор."""
    return await service.unblock(courier_id)


# --- Геолокация ---

@router.post("/couriers/me/location")
async def update_location(
    data: LocationUpdate,
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[CourierService, Depends(_get_service)],
):
    """Обновить текущие координаты курьера. Пишет в Redis и публикует событие в Kafka."""
    return await service.update_location(current_user, data)
