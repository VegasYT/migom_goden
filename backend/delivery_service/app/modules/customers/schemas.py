from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class PaymentMethodType(str, Enum):
    card = "card"
    cash = "cash"
    sbp = "sbp"


# --- Адреса ---

class AddressCreate(BaseModel):
    label: str = Field(default="Другое", max_length=255)
    address: str = Field(..., max_length=255)
    apartment: str | None = Field(default=None, max_length=255)
    floor: int | None = None
    entrance: int | None = None
    intercom: str | None = Field(default=None, max_length=255)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)


class AddressUpdate(BaseModel):
    label: str | None = Field(default=None, max_length=255)
    address: str | None = Field(default=None, max_length=255)
    apartment: str | None = None
    floor: int | None = None
    entrance: int | None = None
    intercom: str | None = None
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)


class AddressResponse(BaseModel):
    id: int
    customer_id: int
    label: str
    address: str
    apartment: str | None
    floor: int | None
    entrance: int | None
    intercom: str | None
    latitude: float | None
    longitude: float | None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# --- Способы оплаты ---

class PaymentMethodCreate(BaseModel):
    type: PaymentMethodType
    title: str = Field(..., max_length=255, examples=["Наличные", "Карта •••• 4242", "СБП"])


class PaymentMethodResponse(BaseModel):
    id: int
    type: PaymentMethodType
    title: str
    is_default: bool
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}
