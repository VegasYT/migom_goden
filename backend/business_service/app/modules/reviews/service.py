from app.modules.reviews.exceptions import (
    ReviewAccessDeniedError,
    ReviewAlreadyExistsError,
    ReviewNotFoundError,
)
from app.modules.reviews.repository import ReviewRepository
from app.modules.reviews.schemas import ReviewCreate, ReviewListResponse, ReviewResponse
from app.modules.users.models import User


class ReviewService:
    def __init__(self, repo: ReviewRepository) -> None:
        self._repo = repo

    async def create(self, data: ReviewCreate, current_user: User) -> ReviewResponse:
        # Один отзыв на один заказ
        existing = await self._repo.get_by_order_id(data.order_id)
        if existing:
            raise ReviewAlreadyExistsError()

        review = await self._repo.create(
            order_id=data.order_id,
            customer_id=current_user.id,
            rating=data.rating,
            comment=data.comment,
        )
        return ReviewResponse.model_validate(review)

    async def get_by_id(self, review_id: int) -> ReviewResponse:
        review = await self._repo.get_by_id(review_id)
        if not review:
            raise ReviewNotFoundError()
        return ReviewResponse.model_validate(review)

    async def list_reviews(self, offset: int, limit: int) -> ReviewListResponse:
        reviews, total = await self._repo.list_all(offset=offset, limit=limit)
        return ReviewListResponse(
            items=[ReviewResponse.model_validate(r) for r in reviews],
            total=total,
        )

    async def delete(self, review_id: int, current_user: User) -> None:
        review = await self._repo.get_by_id(review_id)
        if not review:
            raise ReviewNotFoundError()

        is_author = review.customer_id == current_user.id
        is_moderator = current_user.role.name == "moderator"
        if not is_author and not is_moderator:
            raise ReviewAccessDeniedError()

        await self._repo.delete(review)
