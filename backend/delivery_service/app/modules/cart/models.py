from datetime import datetime

from sqlalchemy import DateTime, Integer, SmallInteger, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class BucketItem(Base):
    __tablename__ = "bucket_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    # FK на таблицы business_service - только ID, без constraint
    customer_id: Mapped[int] = mapped_column(Integer, nullable=False)
    company_id: Mapped[int] = mapped_column(Integer, nullable=False)
    catalog_item_id: Mapped[int] = mapped_column(Integer, nullable=False)
    quantity: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    added_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
