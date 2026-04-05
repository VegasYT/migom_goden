from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import require_roles
from app.db.session import get_db
from app.modules.promo.repository import PromoBannerRepository
from app.modules.promo.schemas import (
    PromoBannerCreate,
    PromoBannerListResponse,
    PromoBannerResponse,
    PromoBannerUpdate,
)
from app.modules.promo.service import PromoBannerService
from app.modules.users.models import User

router = APIRouter(prefix="/promo-banners", tags=["Промо-баннеры"])


def _get_service(session: Annotated[AsyncSession, Depends(get_db)]) -> PromoBannerService:
    return PromoBannerService(PromoBannerRepository(session))


@router.get("", response_model=PromoBannerListResponse)
async def list_banners(
    service: Annotated[PromoBannerService, Depends(_get_service)],
):
    """Список активных баннеров, отсортированных по sort_order (публично, кэш 5 мин)."""
    return await service.list_active()


@router.post("", response_model=PromoBannerResponse, status_code=201)
async def create_banner(
    data: PromoBannerCreate,
    service: Annotated[PromoBannerService, Depends(_get_service)],
    current_user: Annotated[User, Depends(require_roles("moderator"))],
):
    """Создать баннер. Только moderator."""
    return await service.create(data, current_user)


@router.patch("/{banner_id}", response_model=PromoBannerResponse)
async def update_banner(
    banner_id: int,
    data: PromoBannerUpdate,
    service: Annotated[PromoBannerService, Depends(_get_service)],
    current_user: Annotated[User, Depends(require_roles("moderator"))],
):
    """Обновить баннер. Только moderator."""
    return await service.update(banner_id, data, current_user)


@router.delete("/{banner_id}", status_code=204)
async def delete_banner(
    banner_id: int,
    service: Annotated[PromoBannerService, Depends(_get_service)],
    current_user: Annotated[User, Depends(require_roles("moderator"))],
):
    """Удалить баннер. Только moderator."""
    await service.delete(banner_id, current_user)
