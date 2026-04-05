from datetime import datetime
from enum import Enum as PyEnum

import sqlalchemy as sa
from sqlalchemy import Boolean, DateTime, Enum, Integer, Numeric, SmallInteger, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class MovementType(PyEnum):
    walk = "walk"
    scooter = "scooter"
    car = "car"


class Courier(Base):
    __tablename__ = "couriers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    # FK на users из business_service - храним только ID, без constraint
    user_id: Mapped[int] = mapped_column(Integer, nullable=False, unique=True)
    is_blocked: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    type_movement: Mapped[MovementType | None] = mapped_column(
        Enum(MovementType, name="enum_movement_type"), nullable=True
    )
    radius_km: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=5, server_default=sa.text("5"))
    # Центр зоны поиска заказов. Если не задан - используется current_latitude/longitude
    zone_latitude: Mapped[float | None] = mapped_column(Numeric(9, 6), nullable=True)
    zone_longitude: Mapped[float | None] = mapped_column(Numeric(9, 6), nullable=True)
    current_latitude: Mapped[float | None] = mapped_column(Numeric(9, 6), nullable=True)
    current_longitude: Mapped[float | None] = mapped_column(Numeric(9, 6), nullable=True)
    location_updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    shifts: Mapped[list["Shift"]] = relationship("Shift", back_populates="courier")
