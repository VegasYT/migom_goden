from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import require_roles
from app.db.session import get_db
from app.modules.discounts.repository import DiscountRepository, PromoCodeRepository
from app.modules.discounts.schemas import (
    DiscountCreate,
    DiscountListResponse,
    DiscountResponse,
    DiscountUpdate,
    PromoCodeCreate,
    PromoCodeResponse,
)
from app.modules.discounts.service import DiscountService, PromoCodeService
from app.modules.users.models import User

router = APIRouter(tags=["Скидки и промокоды"])


def _get_discount_service(session: Annotated[AsyncSession, Depends(get_db)]) -> DiscountService:
    return DiscountService(DiscountRepository(session))


def _get_promo_service(session: Annotated[AsyncSession, Depends(get_db)]) -> PromoCodeService:
    return PromoCodeService(PromoCodeRepository(session))


# --- Скидки ---

@router.post("/discounts", response_model=DiscountResponse, status_code=201)
async def create_discount(
    data: DiscountCreate,
    service: Annotated[DiscountService, Depends(_get_discount_service)],
    current_user: Annotated[User, Depends(require_roles("moderator"))],
):
    """Создать скидку. Только moderator."""
    return await service.create(data, current_user)


@router.get("/discounts", response_model=DiscountListResponse)
async def list_discounts(
    service: Annotated[DiscountService, Depends(_get_discount_service)],
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    """Список активных скидок (публично, кэш 5 мин)."""
    return await service.list_active(offset=offset, limit=limit)


@router.get("/discounts/{discount_id}", response_model=DiscountResponse)
async def get_discount(
    discount_id: int,
    service: Annotated[DiscountService, Depends(_get_discount_service)],
):
    """Получить скидку по ID."""
    return await service.get_by_id(discount_id)


@router.patch("/discounts/{discount_id}", response_model=DiscountResponse)
async def update_discount(
    discount_id: int,
    data: DiscountUpdate,
    service: Annotated[DiscountService, Depends(_get_discount_service)],
    current_user: Annotated[User, Depends(require_roles("moderator"))],
):
    """Обновить скидку. Только moderator."""
    return await service.update(discount_id, data, current_user)


@router.delete("/discounts/{discount_id}", status_code=204)
async def delete_discount(
    discount_id: int,
    service: Annotated[DiscountService, Depends(_get_discount_service)],
    current_user: Annotated[User, Depends(require_roles("moderator"))],
):
    """Удалить скидку. Только moderator."""
    await service.delete(discount_id, current_user)


# --- Промокоды ---

@router.post("/promo-codes", response_model=PromoCodeResponse, status_code=201)
async def create_promo_code(
    data: PromoCodeCreate,
    service: Annotated[PromoCodeService, Depends(_get_promo_service)],
    current_user: Annotated[User, Depends(require_roles("moderator"))],
):
    """Создать промокод. Только moderator."""
    return await service.create(data, current_user)


@router.get("/promo-codes/{code}", response_model=PromoCodeResponse)
async def get_promo_code(
    code: str,
    service: Annotated[PromoCodeService, Depends(_get_promo_service)],
):
    """Проверить промокод по коду (публично)."""
    return await service.get_by_code(code)


@router.delete("/promo-codes/{promo_id}", status_code=204)
async def delete_promo_code(
    promo_id: int,
    service: Annotated[PromoCodeService, Depends(_get_promo_service)],
    current_user: Annotated[User, Depends(require_roles("moderator"))],
):
    """Удалить промокод. Только moderator."""
    await service.delete(promo_id, current_user)
