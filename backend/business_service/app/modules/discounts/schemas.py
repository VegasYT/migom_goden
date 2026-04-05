from datetime import datetime

from pydantic import BaseModel, Field

from app.modules.discounts.models import DiscountTarget, DiscountType


class DiscountCreate(BaseModel):
    target: DiscountTarget
    company_id: int | None = None
    catalog_item_id: int | None = None
    label: str | None = None
    discount_type: DiscountType
    discount_value: int = Field(..., ge=1)
    is_active: bool = True
    starts_at: datetime
    ends_at: datetime | None = None


class DiscountUpdate(BaseModel):
    label: str | None = None
    discount_value: int | None = Field(None, ge=1)
    is_active: bool | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None


class DiscountResponse(BaseModel):
    id: int
    target: DiscountTarget
    company_id: int | None
    catalog_item_id: int | None
    label: str | None
    discount_type: DiscountType
    discount_value: int
    is_active: bool
    starts_at: datetime
    ends_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}


class DiscountListResponse(BaseModel):
    items: list[DiscountResponse]
    total: int


# --- Промокоды ---

class PromoCodeCreate(BaseModel):
    code: str
    discount_type: DiscountType
    discount_value: int = Field(..., ge=1)
    min_order_price: int | None = None
    uses_left: int | None = None
    expires_at: datetime
    is_active: bool = True
    timezone: str = "UTC"


class PromoCodeResponse(BaseModel):
    id: int
    code: str
    discount_type: DiscountType
    discount_value: int
    min_order_price: int | None
    uses_left: int | None
    expires_at: datetime
    is_active: bool
    created_at: datetime
    timezone: str

    model_config = {"from_attributes": True}
