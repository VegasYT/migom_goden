from datetime import datetime

from pydantic import BaseModel


class CompanyCreate(BaseModel):
    name: str
    description: str | None = None


class CompanyUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    is_active: bool | None = None


class CompanyResponse(BaseModel):
    id: int
    owner_id: int
    name: str
    description: str | None
    cover_url: str | None
    is_active: bool
    is_blocked: bool
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class CompanyListResponse(BaseModel):
    items: list[CompanyResponse]
    total: int
