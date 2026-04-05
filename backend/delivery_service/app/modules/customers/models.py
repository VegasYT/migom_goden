from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import Boolean, DateTime, Enum, Integer, Numeric, SmallInteger, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class PaymentMethodType(PyEnum):
    card = "card"
    cash = "cash"
    sbp = "sbp"


class CustomerAddress(Base):
    __tablename__ = "customer_addresses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    # FK на users из business_service - только ID
    customer_id: Mapped[int] = mapped_column(Integer, nullable=False)
    label: Mapped[str] = mapped_column(String(255), nullable=False, default="Другое")
    address: Mapped[str] = mapped_column(String(255), nullable=False)
    apartment: Mapped[str | None] = mapped_column(String(255), nullable=True)
    floor: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    entrance: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    intercom: Mapped[str | None] = mapped_column(String(255), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Numeric(9, 6), nullable=True)
    longitude: Mapped[float | None] = mapped_column(Numeric(9, 6), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )


class CustomerPaymentMethod(Base):
    __tablename__ = "customer_payment_methods"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    # FK на users из business_service - только ID
    customer_id: Mapped[int] = mapped_column(Integer, nullable=False)
    provider: Mapped[str] = mapped_column(
        String(255), nullable=False, default="stub_provider"
    )
    provider_token: Mapped[str] = mapped_column(
        String(255), nullable=False, default="stub_token"
    )
    type: Mapped[PaymentMethodType] = mapped_column(
        Enum(PaymentMethodType, name="enum_payment_method"), nullable=False
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    is_default: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
