from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, SmallInteger, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class PromoBanner(Base):
    __tablename__ = "promo_banners"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    subtitle: Mapped[str] = mapped_column(String(255), nullable=False)
    badge: Mapped[str | None] = mapped_column(String(255), nullable=True)
    color_start: Mapped[str] = mapped_column(String(255), nullable=False)
    color_end: Mapped[str] = mapped_column(String(255), nullable=False)
    sort_order: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
