from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, Numeric, SmallInteger, String, Time, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.modules.users.models import User


class Outlet(Base):
    __tablename__ = "outlets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    company_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("companies.id", ondelete="NO ACTION"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    address: Mapped[str] = mapped_column(String(512), nullable=False)
    latitude: Mapped[float] = mapped_column(Numeric(9, 6), nullable=False)
    longitude: Mapped[float] = mapped_column(Numeric(9, 6), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    delivery_fee: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    free_delivery_from: Mapped[int | None] = mapped_column(Integer, nullable=True)
    min_order_price: Mapped[int | None] = mapped_column(Integer, nullable=True)
    opens_at: Mapped[str] = mapped_column(Time, nullable=False, server_default="00:00:00")
    closes_at: Mapped[str] = mapped_column(Time, nullable=False, server_default="23:59:59")
    timezone: Mapped[str] = mapped_column(String(255), nullable=False, server_default="UTC")

    company: Mapped["Company"] = relationship("Company", back_populates="outlets")


class OutletManager(Base):
    """Менеджеры торговых точек - назначаются владельцем компании."""
    __tablename__ = "outlet_managers"
    __table_args__ = (UniqueConstraint("outlet_id", "user_id", name="uq_outlet_manager"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    outlet_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("outlets.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    added_by: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="NO ACTION"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )

    user: Mapped["User"] = relationship("User", foreign_keys=[user_id])


class OutletItemAvailability(Base):
    """Переопределяет доступность товара для конкретной точки. Если записи нет - товар доступен."""
    __tablename__ = "outlet_item_availability"
    __table_args__ = (UniqueConstraint("outlet_id", "catalog_item_id", name="uq_outlet_item"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    outlet_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("outlets.id", ondelete="CASCADE"), nullable=False
    )
    catalog_item_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("catalog_items.id", ondelete="CASCADE"), nullable=False
    )
    is_available: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    # null = не отслеживаем, 0 = нет в наличии, N = остаток
    stock_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
