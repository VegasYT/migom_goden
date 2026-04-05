from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field, field_validator


class MovementType(str, Enum):
    walk = "walk"
    scooter = "scooter"
    car = "car"


class CourierResponse(BaseModel):
    id: int
    user_id: int
    is_blocked: bool
    type_movement: MovementType | None
    radius_km: int
    zone_latitude: float | None
    zone_longitude: float | None
    current_latitude: float | None
    current_longitude: float | None
    location_updated_at: datetime | None

    model_config = {"from_attributes": True}


class CourierListResponse(BaseModel):
    items: list[CourierResponse]
    total: int


class CourierProfileUpdate(BaseModel):
    type_movement: MovementType | None = None
    radius_km: int | None = Field(default=None, ge=1, le=100)
    zone_latitude: float | None = Field(default=None, ge=-90, le=90)
    zone_longitude: float | None = Field(default=None, ge=-180, le=180)


class LocationUpdate(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
