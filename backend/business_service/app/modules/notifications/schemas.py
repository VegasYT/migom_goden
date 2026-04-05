from datetime import datetime

from pydantic import BaseModel

from app.modules.notifications.models import NotificationType


class NotificationResponse(BaseModel):
    id: int
    user_id: int
    type: NotificationType
    title: str
    body: str
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class NotificationListResponse(BaseModel):
    items: list[NotificationResponse]
    total: int
