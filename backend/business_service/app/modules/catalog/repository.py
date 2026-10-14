import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.catalog.models import CatalogCategory, CatalogItem
from collections import defaultdict


class CatalogRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    # --- Категории ---

    async def get_category_by_id(self, category_id: int) -> CatalogCategory | None:
        result = await self._session.execute(
            select(CatalogCategory).where(CatalogCategory.id == category_id)
        )
        return result.scalar_one_or_none()

    async def list_categories(self, search: str | None = None) -> list[CatalogCategory]:
        query = select(CatalogCategory).where(CatalogCategory.is_active == True)  # noqa: E712
        if search:
            query = query.where(CatalogCategory.name.ilike(f"%{search}%"))
        result = await self._session.execute(query.order_by(CatalogCategory.sort_order))
        return list(result.scalars().all())

    async def list_categories_all(self, search: str | None = None) -> list[CatalogCategory]:
        """Все категории включая неактивные - для модератора."""
        query = select(CatalogCategory)
        if search:
            query = query.where(CatalogCategory.name.ilike(f"%{search}%"))
        result = await self._session.execute(query.order_by(CatalogCategory.sort_order))
        return list(result.scalars().all())

    async def create_category(self, name: str, emoji: str, sort_order: int) -> CatalogCategory:
        category = CatalogCategory(name=name, emoji=emoji, sort_order=sort_order)
        self._session.add(category)
        await self._session.flush()
        return category

    async def update_category(self, category: CatalogCategory, **fields) -> CatalogCategory:
        for key, value in fields.items():
            if value is not None:
                setattr(category, key, value)
        await self._session.flush()
        await self._session.refresh(category)
        return category

    async def delete_category(self, category: CatalogCategory) -> None:
        await self._session.delete(category)
        await self._session.flush()

    # --- Позиции меню ---

    async def get_item_by_id(self, item_id: int) -> CatalogItem | None:
        result = await self._session.execute(
            select(CatalogItem).where(CatalogItem.id == item_id)
        )
        return result.scalar_one_or_none()

    async def list_items(self, company_id: int) -> list[CatalogItem]:
        result = await self._session.execute(
            select(CatalogItem).where(CatalogItem.company_id == company_id)
        )
        return list(result.scalars().all())

    async def list_items_with_categories(self, company_id: int) -> list[CatalogItem]:
        """Items компании с подгруженной категорией - для построения меню."""
        result = await self._session.execute(
            select(CatalogItem)
            .options(selectinload(CatalogItem.category))
            .where(CatalogItem.company_id == company_id, CatalogItem.is_active == True)  # noqa: E712
            .order_by(CatalogItem.category_id)
        )
        return list(result.scalars().all())

    async def create_item(
        self,
        company_id: int,
        category_id: int,
        name: str,
        price: float,
        description: str | None,
        goden_dish_id: uuid.UUID | None = None,
    ) -> CatalogItem:
        item = CatalogItem(
            company_id=company_id,
            category_id=category_id,
            name=name,
            price=price,
            description=description,
            goden_dish_id=goden_dish_id,
        )
        self._session.add(item)
        await self._session.flush()
        return item

    async def update_item(self, item: CatalogItem, **fields) -> CatalogItem:
        for key, value in fields.items():
            if value is not None:
                setattr(item, key, value)
        await self._session.flush()
        await self._session.refresh(item)
        return item

    async def update_item_fields(self, item: CatalogItem, **fields) -> CatalogItem:
        """Как update_item, но записывает и None: так снимается связь с блюдом Goden."""
        for key, value in fields.items():
            setattr(item, key, value)
        await self._session.flush()
        await self._session.refresh(item)
        return item

    async def flush(self) -> None:
        await self._session.flush()

    async def delete_item(self, item: CatalogItem) -> None:
        await self._session.delete(item)
        await self._session.flush()
