from datetime import datetime

from pydantic import BaseModel


class PromoBannerCreate(BaseModel):
    title: str
    subtitle: str
    badge: str | None = None
    color_start: str
    color_end: str
    sort_order: int = 0
    is_active: bool = True


class PromoBannerUpdate(BaseModel):
    title: str | None = None
    subtitle: str | None = None
    badge: str | None = None
    color_start: str | None = None
    color_end: str | None = None
    sort_order: int | None = None
    is_active: bool | None = None


class PromoBannerResponse(BaseModel):
    id: int
    title: str
    subtitle: str
    badge: str | None
    color_start: str
    color_end: str
    sort_order: int
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class PromoBannerListResponse(BaseModel):
    items: list[PromoBannerResponse]
    total: int
