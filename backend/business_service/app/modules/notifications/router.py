from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.modules.notifications.repository import NotificationRepository
from app.modules.notifications.schemas import NotificationListResponse, NotificationResponse
from app.modules.notifications.service import NotificationService
from app.modules.users.models import User

router = APIRouter(prefix="/notifications", tags=["Уведомления"])


def _get_service(session: Annotated[AsyncSession, Depends(get_db)]) -> NotificationService:
    return NotificationService(NotificationRepository(session))


@router.get("", response_model=NotificationListResponse)
async def list_notifications(
    service: Annotated[NotificationService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    """Список уведомлений текущего пользователя."""
    return await service.list_for_user(current_user, offset=offset, limit=limit)


@router.post("/read-all", status_code=204)
async def mark_all_read(
    service: Annotated[NotificationService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Отметить все уведомления текущего пользователя прочитанными."""
    await service.mark_all_read(current_user)


@router.post("/{notification_id}/read", response_model=NotificationResponse)
async def mark_notification_read(
    notification_id: int,
    service: Annotated[NotificationService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Отметить конкретное уведомление прочитанным."""
    return await service.mark_read(notification_id, current_user)
