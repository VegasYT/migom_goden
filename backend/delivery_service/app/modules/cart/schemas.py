from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class CartItemAdd(BaseModel):
    catalog_item_id: int
    quantity: int = Field(default=1, ge=1, le=100)


class CartItemUpdate(BaseModel):
    quantity: int = Field(..., ge=1, le=100)


class CartItemResponse(BaseModel):
    id: int
    catalog_item_id: int
    company_id: int
    name: str
    price: Decimal
    quantity: int
    subtotal: Decimal
    added_at: datetime

    model_config = {"from_attributes": False}


class CartResponse(BaseModel):
    """Корзина одной компании."""
    company_id: int
    items: list[CartItemResponse]
    total: Decimal


class AllCartsResponse(BaseModel):
    """Все корзины покупателя, сгруппированные по компаниям."""
    carts: list[CartResponse]
    grand_total: Decimal
