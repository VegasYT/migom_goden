import uuid
from datetime import time
from decimal import Decimal

from pydantic import BaseModel, field_validator

from app.modules.catalog.schemas import CategoryWithItemsResponse


class OutletCreate(BaseModel):
    name: str
    address: str
    latitude: Decimal
    longitude: Decimal
    delivery_fee: int = 0
    free_delivery_from: int | None = None
    min_order_price: int | None = None
    opens_at: time = time(0, 0, 0)
    closes_at: time = time(23, 59, 59)
    timezone: str = "UTC"

    @field_validator("latitude")
    @classmethod
    def validate_latitude(cls, v: Decimal) -> Decimal:
        if not (-90 <= v <= 90):
            raise ValueError("Широта должна быть в диапазоне [-90, 90]")
        return v

    @field_validator("longitude")
    @classmethod
    def validate_longitude(cls, v: Decimal) -> Decimal:
        if not (-180 <= v <= 180):
            raise ValueError("Долгота должна быть в диапазоне [-180, 180]")
        return v


class OutletUpdate(BaseModel):
    name: str | None = None
    address: str | None = None
    latitude: Decimal | None = None
    longitude: Decimal | None = None
    is_active: bool | None = None
    delivery_fee: int | None = None
    free_delivery_from: int | None = None
    min_order_price: int | None = None
    opens_at: time | None = None
    closes_at: time | None = None
    timezone: str | None = None


class OutletResponse(BaseModel):
    id: int
    company_id: int
    name: str
    address: str
    latitude: Decimal
    longitude: Decimal
    is_active: bool
    delivery_fee: int
    free_delivery_from: int | None
    min_order_price: int | None
    opens_at: time
    closes_at: time
    timezone: str
    goden_point_id: uuid.UUID | None = None

    model_config = {"from_attributes": True}


class ItemAvailabilityUpdate(BaseModel):
    is_available: bool
    stock_count: int | None = None


class ItemAvailabilityResponse(BaseModel):
    outlet_id: int
    catalog_item_id: int
    is_available: bool
    stock_count: int | None

    model_config = {"from_attributes": True}


class ItemAvailabilityWithInfoResponse(BaseModel):
    catalog_item_id: int
    name: str
    is_available: bool
    stock_count: int | None


class OutletMenuResponse(BaseModel):
    outlet_id: int
    categories: list[CategoryWithItemsResponse]


class OutletManagerAdd(BaseModel):
    email: str


class OutletManagerResponse(BaseModel):
    id: int
    outlet_id: int
    user_id: int
    user_full_name: str
    user_email: str
    added_by: int
    created_at: str

    model_config = {"from_attributes": False}
