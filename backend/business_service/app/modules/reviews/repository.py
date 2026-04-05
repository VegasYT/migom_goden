from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.reviews.models import Review


class ReviewRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, review_id: int) -> Review | None:
        result = await self._session.execute(
            select(Review).where(Review.id == review_id)
        )
        return result.scalar_one_or_none()

    async def get_by_order_id(self, order_id: int) -> Review | None:
        """Проверка: уже есть отзыв на данный заказ."""
        result = await self._session.execute(
            select(Review).where(Review.order_id == order_id)
        )
        return result.scalar_one_or_none()

    async def list_all(
        self,
        offset: int = 0,
        limit: int = 20,
        company_id: int | None = None,
    ) -> tuple[list[Review], int]:
        query = select(Review)
        count_query = select(func.count(Review.id))

        # Фильтрация по company_id происходит через join с заказами,
        # но поскольку order_id из внешнего сервиса, фильтр применяется на уровне сервиса.
        # Здесь возвращаем все записи (фильтрация по customer_id при необходимости).
        total_result = await self._session.execute(count_query)
        total = total_result.scalar_one()

        result = await self._session.execute(
            query.order_by(Review.created_at.desc()).offset(offset).limit(limit)
        )
        return list(result.scalars().all()), total

    async def create(
        self,
        order_id: int,
        customer_id: int,
        rating: int,
        comment: str | None,
    ) -> Review:
        review = Review(
            order_id=order_id,
            customer_id=customer_id,
            rating=rating,
            comment=comment,
        )
        self._session.add(review)
        await self._session.flush()
        await self._session.refresh(review)
        return review

    async def delete(self, review: Review) -> None:
        await self._session.delete(review)
        await self._session.flush()
