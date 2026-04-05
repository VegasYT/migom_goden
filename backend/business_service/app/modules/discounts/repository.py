from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.discounts.models import Discount, PromoCode


class DiscountRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, discount_id: int) -> Discount | None:
        result = await self._session.execute(
            select(Discount).where(Discount.id == discount_id)
        )
        return result.scalar_one_or_none()

    async def list_active(self, offset: int = 0, limit: int = 20) -> tuple[list[Discount], int]:
        now = datetime.now(timezone.utc)
        base = select(Discount).where(
            Discount.is_active == True,
            Discount.starts_at <= now,
        )
        total_result = await self._session.execute(
            select(func.count()).select_from(base.subquery())
        )
        total = total_result.scalar_one()

        result = await self._session.execute(
            base.order_by(Discount.created_at.desc()).offset(offset).limit(limit)
        )
        return list(result.scalars().all()), total

    async def create(self, **fields) -> Discount:
        discount = Discount(**fields)
        self._session.add(discount)
        await self._session.flush()
        await self._session.refresh(discount)
        return discount

    async def update(self, discount: Discount, **fields) -> Discount:
        for key, value in fields.items():
            if value is not None:
                setattr(discount, key, value)
        await self._session.flush()
        await self._session.refresh(discount)
        return discount

    async def delete(self, discount: Discount) -> None:
        await self._session.delete(discount)
        await self._session.flush()


class PromoCodeRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, promo_id: int) -> PromoCode | None:
        result = await self._session.execute(
            select(PromoCode).where(PromoCode.id == promo_id)
        )
        return result.scalar_one_or_none()

    async def get_by_code(self, code: str) -> PromoCode | None:
        result = await self._session.execute(
            select(PromoCode).where(PromoCode.code == code)
        )
        return result.scalar_one_or_none()

    async def create(self, **fields) -> PromoCode:
        promo = PromoCode(**fields)
        self._session.add(promo)
        await self._session.flush()
        await self._session.refresh(promo)
        return promo

    async def delete(self, promo: PromoCode) -> None:
        await self._session.delete(promo)
        await self._session.flush()
