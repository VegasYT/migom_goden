from datetime import datetime

from pydantic import BaseModel, Field


class ReviewCreate(BaseModel):
    order_id: int
    rating: int = Field(..., ge=1, le=5)
    comment: str | None = Field(None, max_length=255)


class ReviewResponse(BaseModel):
    id: int
    order_id: int
    customer_id: int
    rating: int
    comment: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ReviewListResponse(BaseModel):
    items: list[ReviewResponse]
    total: int
