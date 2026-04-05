from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.modules.catalog.repository import CatalogRepository
from app.modules.companies.repository import CompanyRepository
from app.modules.outlets.repository import OutletRepository
from app.modules.outlets.schemas import (
    ItemAvailabilityResponse,
    ItemAvailabilityUpdate,
    ItemAvailabilityWithInfoResponse,
    OutletCreate,
    OutletManagerAdd,
    OutletManagerResponse,
    OutletMenuResponse,
    OutletResponse,
    OutletUpdate,
)
from app.modules.outlets.service import OutletService
from app.modules.users.models import User

router = APIRouter(tags=["Торговые точки"])


def _get_service(session: Annotated[AsyncSession, Depends(get_db)]) -> OutletService:
    return OutletService(
        OutletRepository(session),
        CompanyRepository(session),
        CatalogRepository(session),
    )


@router.get("/companies/{company_id}/outlets", response_model=list[OutletResponse])
async def list_outlets(
    company_id: int,
    service: Annotated[OutletService, Depends(_get_service)],
):
    """Список всех торговых точек компании."""
    return await service.list_outlets(company_id)


@router.post("/companies/{company_id}/outlets", response_model=OutletResponse, status_code=201)
async def create_outlet(
    company_id: int,
    data: OutletCreate,
    service: Annotated[OutletService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Создать торговую точку компании. Только owner компании."""
    return await service.create_outlet(company_id, data, current_user)


@router.get("/outlets/{outlet_id}", response_model=OutletResponse)
async def get_outlet(
    outlet_id: int,
    service: Annotated[OutletService, Depends(_get_service)],
):
    """Получить торговую точку по ID."""
    return await service.get_outlet(outlet_id)


@router.patch("/outlets/{outlet_id}", response_model=OutletResponse)
async def update_outlet(
    outlet_id: int,
    data: OutletUpdate,
    service: Annotated[OutletService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Обновить данные торговой точки. Только owner компании или moderator."""
    outlet = await service.get_outlet(outlet_id)
    return await service.update_outlet(outlet.company_id, outlet_id, data, current_user)


@router.delete("/outlets/{outlet_id}", status_code=204)
async def delete_outlet(
    outlet_id: int,
    service: Annotated[OutletService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Удалить торговую точку. Только owner компании или moderator."""
    outlet = await service.get_outlet(outlet_id)
    await service.delete_outlet(outlet.company_id, outlet_id, current_user)


@router.get("/outlets/{outlet_id}/menu", response_model=OutletMenuResponse)
async def get_outlet_menu(
    outlet_id: int,
    service: Annotated[OutletService, Depends(_get_service)],
):
    """Меню точки: только доступные товары, сгруппированные по категориям."""
    return await service.get_outlet_menu(outlet_id)


@router.get(
    "/outlets/{outlet_id}/items/availability",
    response_model=list[ItemAvailabilityWithInfoResponse],
)
async def list_items_availability(
    outlet_id: int,
    service: Annotated[OutletService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Все товары точки с остатками и статусом доступности. Только owner/moderator."""
    return await service.list_items_availability(outlet_id, current_user)


@router.patch(
    "/outlets/{outlet_id}/items/{item_id}/availability",
    response_model=ItemAvailabilityResponse,
)
async def set_item_availability(
    outlet_id: int,
    item_id: int,
    data: ItemAvailabilityUpdate,
    service: Annotated[OutletService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Установить доступность и остаток конкретного товара на точке. Только owner/moderator."""
    return await service.set_item_availability(outlet_id, item_id, data, current_user)


# --- Менеджеры точек ---

@router.get("/outlets/{outlet_id}/managers", response_model=list[OutletManagerResponse])
async def list_managers(
    outlet_id: int,
    service: Annotated[OutletService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Список менеджеров торговой точки. Только owner/moderator."""
    return await service.list_managers(outlet_id, current_user)


@router.post("/outlets/{outlet_id}/managers", response_model=OutletManagerResponse, status_code=201)
async def add_manager(
    outlet_id: int,
    data: OutletManagerAdd,
    service: Annotated[OutletService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Добавить менеджера на точку. Пользователь должен иметь роль outlet_manager. Только owner/moderator."""
    return await service.add_manager(outlet_id, data.email, current_user)


@router.delete("/outlets/{outlet_id}/managers/{user_id}", status_code=204)
async def remove_manager(
    outlet_id: int,
    user_id: int,
    service: Annotated[OutletService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Удалить менеджера с точки. Только owner/moderator."""
    await service.remove_manager(outlet_id, user_id, current_user)
