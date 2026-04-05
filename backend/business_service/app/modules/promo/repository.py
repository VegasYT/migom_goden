from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.promo.models import PromoBanner


class PromoBannerRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, banner_id: int) -> PromoBanner | None:
        result = await self._session.execute(
            select(PromoBanner).where(PromoBanner.id == banner_id)
        )
        return result.scalar_one_or_none()

    async def list_active(self) -> tuple[list[PromoBanner], int]:
        base = select(PromoBanner).where(PromoBanner.is_active == True)

        total_result = await self._session.execute(
            select(func.count()).select_from(base.subquery())
        )
        total = total_result.scalar_one()

        result = await self._session.execute(
            base.order_by(PromoBanner.sort_order.asc())
        )
        return list(result.scalars().all()), total

    async def create(self, **fields) -> PromoBanner:
        banner = PromoBanner(**fields)
        self._session.add(banner)
        await self._session.flush()
        await self._session.refresh(banner)
        return banner

    async def update(self, banner: PromoBanner, **fields) -> PromoBanner:
        for key, value in fields.items():
            if value is not None:
                setattr(banner, key, value)
        await self._session.flush()
        await self._session.refresh(banner)
        return banner

    async def delete(self, banner: PromoBanner) -> None:
        await self._session.delete(banner)
        await self._session.flush()
