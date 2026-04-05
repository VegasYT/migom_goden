from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.shifts.models import Shift


class ShiftRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_active(self, courier_id: int) -> Shift | None:
        result = await self._session.execute(
            select(Shift).where(
                Shift.courier_id == courier_id,
                Shift.is_active == True,  # noqa: E712
            )
        )
        return result.scalar_one_or_none()

    async def get_by_id(self, shift_id: int) -> Shift | None:
        result = await self._session.execute(
            select(Shift).where(Shift.id == shift_id)
        )
        return result.scalar_one_or_none()

    async def list_by_courier(
        self, courier_id: int, offset: int = 0, limit: int = 20
    ) -> tuple[list[Shift], int]:
        total = await self._session.scalar(
            select(func.count(Shift.id)).where(Shift.courier_id == courier_id)
        )
        result = await self._session.execute(
            select(Shift)
            .where(Shift.courier_id == courier_id)
            .order_by(Shift.started_at.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(result.scalars().all()), total or 0

    async def list_active_all(self, offset: int = 0, limit: int = 20) -> tuple[list[Shift], int]:
        """Все активные смены (онлайн-курьеры) - для модератора."""
        total = await self._session.scalar(
            select(func.count(Shift.id)).where(Shift.is_active == True)  # noqa: E712
        )
        result = await self._session.execute(
            select(Shift)
            .where(Shift.is_active == True)  # noqa: E712
            .order_by(Shift.started_at.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(result.scalars().all()), total or 0

    async def create(self, courier_id: int) -> Shift:
        shift = Shift(courier_id=courier_id, is_active=True)
        self._session.add(shift)
        await self._session.flush()
        await self._session.refresh(shift)
        return shift

    async def end(self, shift: Shift) -> Shift:
        from datetime import datetime, timezone
        shift.ended_at = datetime.now(timezone.utc)
        shift.is_active = False
        await self._session.flush()
        return shift
