from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, field_validator


# --- Категории (глобальные, управляет только модератор) ---

class CategoryCreate(BaseModel):
    name: str
    emoji: str
    sort_order: int = 0


class CategoryUpdate(BaseModel):
    name: str | None = None
    emoji: str | None = None
    sort_order: int | None = None
    is_active: bool | None = None


class CategoryResponse(BaseModel):
    id: int
    name: str
    emoji: str
    sort_order: int
    is_active: bool

    model_config = {"from_attributes": True}


# --- Позиции меню ---

class CatalogItemCreate(BaseModel):
    category_id: int
    name: str
    description: str | None = None
    price: Decimal

    @field_validator("price")
    @classmethod
    def price_positive(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Цена должна быть больше нуля")
        return v


class CatalogItemUpdate(BaseModel):
    category_id: int | None = None
    name: str | None = None
    description: str | None = None
    price: Decimal | None = None
    is_active: bool | None = None

    @field_validator("price")
    @classmethod
    def price_positive(cls, v: Decimal | None) -> Decimal | None:
        if v is not None and v <= 0:
            raise ValueError("Цена должна быть больше нуля")
        return v


class CatalogItemResponse(BaseModel):
    id: int
    category_id: int
    company_id: int
    name: str
    description: str | None
    price: Decimal
    photo_url: str | None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


# --- Меню компании целиком ---

class CategoryWithItemsResponse(BaseModel):
    id: int
    name: str
    emoji: str
    sort_order: int
    is_active: bool
    items: list[CatalogItemResponse]

    model_config = {"from_attributes": True}


class CompanyMenuResponse(BaseModel):
    company_id: int
    categories: list[CategoryWithItemsResponse]
