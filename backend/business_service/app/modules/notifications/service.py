from app.modules.notifications.exceptions import (
    NotificationAccessDeniedError,
    NotificationNotFoundError,
)
from app.modules.notifications.repository import NotificationRepository
from app.modules.notifications.schemas import (
    NotificationListResponse,
    NotificationResponse,
)
from app.modules.users.models import User


class NotificationService:
    def __init__(self, repo: NotificationRepository) -> None:
        self._repo = repo

    async def list_for_user(
        self, current_user: User, offset: int, limit: int
    ) -> NotificationListResponse:
        notifications, total = await self._repo.list_for_user(
            user_id=current_user.id, offset=offset, limit=limit
        )
        return NotificationListResponse(
            items=[NotificationResponse.model_validate(n) for n in notifications],
            total=total,
        )

    async def mark_read(self, notification_id: int, current_user: User) -> NotificationResponse:
        notification = await self._repo.get_by_id(notification_id)
        if not notification:
            raise NotificationNotFoundError()

        # Пользователь может читать только свои уведомления
        if notification.user_id != current_user.id:
            raise NotificationAccessDeniedError()

        updated = await self._repo.mark_read(notification)
        return NotificationResponse.model_validate(updated)

    async def mark_all_read(self, current_user: User) -> None:
        await self._repo.mark_all_read(user_id=current_user.id)
