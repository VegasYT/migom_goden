from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Integer, SmallInteger, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class DiscountTarget(PyEnum):
    company = "company"
    catalog_item = "catalog_item"


class DiscountType(PyEnum):
    percent = "percent"
    fixed = "fixed"


class Discount(Base):
    __tablename__ = "discounts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    target: Mapped[DiscountTarget] = mapped_column(
        Enum(DiscountTarget, name="enum_discount_target"), nullable=False
    )
    company_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("companies.id", ondelete="NO ACTION"), nullable=True
    )
    catalog_item_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("catalog_items.id", ondelete="NO ACTION"), nullable=True
    )
    label: Mapped[str | None] = mapped_column(String(255), nullable=True)
    discount_type: Mapped[DiscountType] = mapped_column(
        Enum(DiscountType, name="enum_discount_type"), nullable=False
    )
    discount_value: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )


class PromoCode(Base):
    __tablename__ = "promo_codes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    discount_type: Mapped[DiscountType] = mapped_column(
        Enum(DiscountType, name="enum_promo_discount_type"), nullable=False
    )
    discount_value: Mapped[int] = mapped_column(Integer, nullable=False)
    min_order_price: Mapped[int | None] = mapped_column(Integer, nullable=True)
    uses_left: Mapped[int | None] = mapped_column(Integer, nullable=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    timezone: Mapped[str] = mapped_column(String(255), nullable=False, server_default="UTC")
