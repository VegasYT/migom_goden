from datetime import datetime

from pydantic import BaseModel


class ShiftResponse(BaseModel):
    id: int
    courier_id: int
    started_at: datetime
    ended_at: datetime | None
    is_active: bool

    model_config = {"from_attributes": True}


class ShiftListResponse(BaseModel):
    items: list[ShiftResponse]
    total: int


class ActiveShiftsResponse(BaseModel):
    """Список активных смен для модератора."""
    items: list[ShiftResponse]
    total: int
