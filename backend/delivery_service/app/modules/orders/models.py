from datetime import datetime
from enum import Enum as PyEnum

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Integer, Numeric, SmallInteger, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class OrderStatus(PyEnum):
    new = "new"
    assigned = "assigned"
    assembling = "assembling"
    ready_for_pickup = "ready_for_pickup"
    in_delivery = "in_delivery"
    delivered = "delivered"
    cancelled = "cancelled"
    received = "received"


class DeliveryType(PyEnum):
    delivery = "delivery"
    pickup = "pickup"


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    # FK на таблицы business_service - только ID, без constraint
    customer_id: Mapped[int] = mapped_column(Integer, nullable=False)
    company_id: Mapped[int] = mapped_column(Integer, nullable=False)
    outlet_id: Mapped[int] = mapped_column(Integer, nullable=False)
    courier_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("couriers.id", ondelete="NO ACTION"), nullable=True
    )
    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus, name="enum_order_status"), nullable=False
    )
    delivery_type: Mapped[DeliveryType] = mapped_column(
        Enum(DeliveryType, name="enum_delivery_type"), nullable=False
    )
    customer_address_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("customer_addresses.id", ondelete="NO ACTION"), nullable=True
    )
    total_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    customer_payment_method_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("customer_payment_methods.id", ondelete="NO ACTION"), nullable=False
    )
    delivery_time: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    leave_at_door: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    # Оффер курьеру: кому предложен заказ и до какого времени
    offered_courier_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    offer_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    items: Mapped[list["OrderItem"]] = relationship(
        "OrderItem", back_populates="order", cascade="all, delete-orphan"
    )
    status_history: Mapped[list["OrderStatusHistory"]] = relationship(
        "OrderStatusHistory", back_populates="order", cascade="all, delete-orphan"
    )


class OrderItem(Base):
    __tablename__ = "order_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    order_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("orders.id", ondelete="NO ACTION"), nullable=False
    )
    # FK на catalog_items из business_service - только ID
    catalog_item_id: Mapped[int] = mapped_column(Integer, nullable=False)
    # Snapshot - цена и название на момент оформления заказа
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)

    order: Mapped["Order"] = relationship("Order", back_populates="items")


class OrderStatusHistory(Base):
    __tablename__ = "order_status_history"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    order_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("orders.id", ondelete="NO ACTION"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(50), nullable=False)
    changed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    # ID пользователя из business_service - только ID
    changed_by: Mapped[int] = mapped_column(Integer, nullable=False)

    order: Mapped["Order"] = relationship("Order", back_populates="status_history")
