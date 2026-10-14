import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, Numeric, String, Text, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class CatalogCategory(Base):
    __tablename__ = "catalog_categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    emoji: Mapped[str] = mapped_column(String(5), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    items: Mapped[list["CatalogItem"]] = relationship("CatalogItem", back_populates="category")


class CatalogItem(Base):
    __tablename__ = "catalog_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    category_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("catalog_categories.id", ondelete="NO ACTION"), nullable=False
    )
    company_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("companies.id", ondelete="NO ACTION"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    photo_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    # блюдо Goden: по нему товар берёт наличие и уходит на кухню
    goden_dish_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )

    category: Mapped["CatalogCategory"] = relationship("CatalogCategory", back_populates="items")
    company: Mapped["Company"] = relationship("Company", back_populates="items")


class CuisineTag(Base):
    __tablename__ = "cuisine_tags"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    emoji: Mapped[str] = mapped_column(String(255), nullable=False)

    companies: Mapped[list["CompanyCuisineTag"]] = relationship(
        "CompanyCuisineTag", back_populates="tag"
    )


class CompanyCuisineTag(Base):
    __tablename__ = "company_cuisine_tags"

    company_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("companies.id", ondelete="NO ACTION"), primary_key=True
    )
    tag_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("cuisine_tags.id", ondelete="NO ACTION"), nullable=False
    )

    company: Mapped["Company"] = relationship("Company", back_populates="cuisine_tags")
    tag: Mapped["CuisineTag"] = relationship("CuisineTag", back_populates="companies")
