from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_access_token, get_current_user
from app.core.goden import GodenClient
from app.db.session import get_db
from app.modules.catalog.repository import CatalogRepository
from app.modules.companies.repository import CompanyRepository
from app.modules.goden.schemas import GodenDishResponse, GodenPointResponse, OutletGodenUpdate
from app.modules.goden.service import GodenBindingService
from app.modules.outlets.repository import OutletRepository
from app.modules.outlets.schemas import OutletResponse
from app.modules.users.models import User

router = APIRouter(tags=["Goden"])


def _get_service(
    session: Annotated[AsyncSession, Depends(get_db)],
    token: Annotated[str, Depends(get_access_token)],
) -> GodenBindingService:
    return GodenBindingService(
        GodenClient(token), OutletRepository(session), CompanyRepository(session), CatalogRepository(session)
    )


@router.get("/goden/points", response_model=list[GodenPointResponse])
async def list_goden_points(
    service: Annotated[GodenBindingService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Работающие точки Goden, которыми владеет пользователь, и подключённые к ним заведения."""
    return await service.owned_points()


@router.put("/outlets/{outlet_id}/goden", response_model=OutletResponse)
async def set_outlet_goden_point(
    outlet_id: int,
    data: OutletGodenUpdate,
    service: Annotated[GodenBindingService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Подключить заведение к своей точке Goden или отключить (point_id: null). Владелец компании."""
    return await service.set_point(outlet_id, data.point_id, current_user)


@router.get("/outlets/{outlet_id}/goden/dishes", response_model=list[GodenDishResponse])
async def list_goden_dishes(
    outlet_id: int,
    service: Annotated[GodenBindingService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Блюда точки Goden подключённого заведения и связанные с ними товары компании."""
    return await service.dishes(outlet_id, current_user)


@router.post("/outlets/{outlet_id}/goden/link-by-name", response_model=list[GodenDishResponse])
async def link_goden_dishes_by_name(
    outlet_id: int,
    service: Annotated[GodenBindingService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Связать блюда Goden без товара с несвязанными товарами того же названия."""
    return await service.link_by_name(outlet_id, current_user)
