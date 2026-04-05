from datetime import datetime
from decimal import Decimal
from enum import Enum

from pydantic import BaseModel, Field, field_validator

from app.modules.customers.schemas import AddressResponse
from app.modules.orders.models import DeliveryType, OrderStatus  # единственный источник enum


# --- Создание заказа ---

class OrderCreate(BaseModel):
    outlet_id: int
    delivery_type: DeliveryType
    customer_payment_method_id: int
    # Для доставки - обязателен сохранённый адрес с координатами
    customer_address_id: int | None = None
    comment: str | None = None
    leave_at_door: bool = False

    @field_validator("customer_address_id")
    @classmethod
    def address_id_must_be_positive(cls, v: int | None) -> int | None:
        if v is not None and v <= 0:
            raise ValueError("customer_address_id должен быть положительным числом")
        return v


# --- Ответы ---

class OrderItemResponse(BaseModel):
    id: int
    catalog_item_id: int
    name: str
    price: Decimal
    quantity: int
    subtotal: Decimal

    model_config = {"from_attributes": False}


class StatusHistoryResponse(BaseModel):
    status: str
    changed_at: datetime
    changed_by: int

    model_config = {"from_attributes": True}


class OrderResponse(BaseModel):
    id: int
    customer_id: int
    company_id: int
    outlet_id: int
    courier_id: int | None
    status: OrderStatus
    delivery_type: DeliveryType
    delivery_address: AddressResponse | None  # None для самовывоза
    total_price: Decimal
    comment: str | None
    customer_payment_method_id: int
    delivery_time: int | None
    leave_at_door: bool
    created_at: datetime
    updated_at: datetime
    items: list[OrderItemResponse] = []
    status_history: list[StatusHistoryResponse] = []

    model_config = {"from_attributes": False}


class OrderListResponse(BaseModel):
    items: list[OrderResponse]
    total: int


# --- Фильтры ---

class SortField(str, Enum):
    created_at = "created_at"
    total_price = "total_price"
    id = "id"


class SortOrder(str, Enum):
    asc = "asc"
    desc = "desc"


class OrderFilters(BaseModel):
    status: OrderStatus | None = None
    outlet_id: int | None = None          # для owner/manager (одна точка)
    outlet_ids: list[int] | None = None   # для модератора (массив точек)
    search: str | None = None             # поиск по ID заказа или комментарию
    date_from: datetime | None = None
    date_to: datetime | None = None
    sort_by: SortField = SortField.created_at
    sort_order: SortOrder = SortOrder.desc
