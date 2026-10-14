import uuid

from pydantic import BaseModel


class GodenPointResponse(BaseModel):
    """Своя работающая точка Goden и заведение Мигома, которое к ней уже подключено."""
    id: uuid.UUID
    name: str
    company_name: str
    outlet_id: int | None


class OutletGodenUpdate(BaseModel):
    # null отключает заведение от точки Goden
    point_id: uuid.UUID | None


class LinkedItem(BaseModel):
    id: int
    name: str


class GodenDishResponse(BaseModel):
    """Блюдо точки Goden и товар компании, связанный с ним."""
    id: uuid.UUID
    name: str
    item: LinkedItem | None
