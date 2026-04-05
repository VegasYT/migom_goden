from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, require_roles
from app.db.session import get_db
from app.modules.reviews.repository import ReviewRepository
from app.modules.reviews.schemas import ReviewCreate, ReviewListResponse, ReviewResponse
from app.modules.reviews.service import ReviewService
from app.modules.users.models import User

router = APIRouter(prefix="/reviews", tags=["Отзывы"])


def _get_service(session: Annotated[AsyncSession, Depends(get_db)]) -> ReviewService:
    return ReviewService(ReviewRepository(session))


@router.post("", response_model=ReviewResponse, status_code=201)
async def create_review(
    data: ReviewCreate,
    service: Annotated[ReviewService, Depends(_get_service)],
    current_user: Annotated[User, Depends(require_roles("customer"))],
):
    """Создать отзыв. Только customer. Один отзыв на один order_id."""
    return await service.create(data, current_user)


@router.get("", response_model=ReviewListResponse)
async def list_reviews(
    service: Annotated[ReviewService, Depends(_get_service)],
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    """Список отзывов (публично)."""
    return await service.list_reviews(offset=offset, limit=limit)


@router.get("/{review_id}", response_model=ReviewResponse)
async def get_review(
    review_id: int,
    service: Annotated[ReviewService, Depends(_get_service)],
):
    """Получить отзыв по ID."""
    return await service.get_by_id(review_id)


@router.delete("/{review_id}", status_code=204)
async def delete_review(
    review_id: int,
    service: Annotated[ReviewService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Удалить отзыв. Доступно автору или moderator."""
    await service.delete(review_id, current_user)
