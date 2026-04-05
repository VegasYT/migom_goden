from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.notifications.models import Notification


class NotificationRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, notification_id: int) -> Notification | None:
        result = await self._session.execute(
            select(Notification).where(Notification.id == notification_id)
        )
        return result.scalar_one_or_none()

    async def list_for_user(
        self,
        user_id: int,
        offset: int = 0,
        limit: int = 20,
    ) -> tuple[list[Notification], int]:
        total_result = await self._session.execute(
            select(func.count(Notification.id)).where(Notification.user_id == user_id)
        )
        total = total_result.scalar_one()

        result = await self._session.execute(
            select(Notification)
            .where(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(result.scalars().all()), total

    async def mark_read(self, notification: Notification) -> Notification:
        notification.is_read = True
        await self._session.flush()
        await self._session.refresh(notification)
        return notification

    async def mark_all_read(self, user_id: int) -> None:
        await self._session.execute(
            update(Notification)
            .where(Notification.user_id == user_id, Notification.is_read == False)
            .values(is_read=True)
        )
        await self._session.flush()
