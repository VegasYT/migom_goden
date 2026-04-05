from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, SmallInteger, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Review(Base):
    __tablename__ = "reviews"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    # FK на orders из delivery_service - только ID
    order_id: Mapped[int] = mapped_column(Integer, nullable=False)
    customer_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="NO ACTION"), nullable=False
    )
    rating: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    comment: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
