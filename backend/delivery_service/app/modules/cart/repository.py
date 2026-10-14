from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.cart.models import BucketItem


class CartRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_item_by_id(self, item_id: int) -> BucketItem | None:
        result = await self._session.execute(
            select(BucketItem).where(BucketItem.id == item_id)
        )
        return result.scalar_one_or_none()

    async def get_existing(self, customer_id: int, catalog_item_id: int) -> BucketItem | None:
        """Возвращает позицию если товар уже есть в корзине."""
        result = await self._session.execute(
            select(BucketItem).where(
                BucketItem.customer_id == customer_id,
                BucketItem.catalog_item_id == catalog_item_id,
            )
        )
        return result.scalar_one_or_none()

    async def list_by_customer(self, customer_id: int) -> list[BucketItem]:
        result = await self._session.execute(
            select(BucketItem)
            .where(BucketItem.customer_id == customer_id)
            .order_by(BucketItem.company_id, BucketItem.added_at)
        )
        return list(result.scalars().all())

    async def list_by_customer_and_company(self, customer_id: int, company_id: int) -> list[BucketItem]:
        result = await self._session.execute(
            select(BucketItem)
            .where(
                BucketItem.customer_id == customer_id,
                BucketItem.company_id == company_id,
            )
            .order_by(BucketItem.added_at)
        )
        return list(result.scalars().all())

    async def add(self, customer_id: int, company_id: int, catalog_item_id: int, quantity: int) -> BucketItem:
        item = BucketItem(
            customer_id=customer_id,
            company_id=company_id,
            catalog_item_id=catalog_item_id,
            quantity=quantity,
        )
        self._session.add(item)
        await self._session.flush()
        await self._session.refresh(item)
        return item

    async def update_quantity(self, item: BucketItem, quantity: int) -> BucketItem:
        item.quantity = quantity
        await self._session.flush()
        return item

    async def delete(self, item: BucketItem) -> None:
        await self._session.delete(item)
        await self._session.flush()

    async def clear_company(self, customer_id: int, company_id: int) -> None:
        """Очистить корзину конкретной компании."""
        items = await self.list_by_customer_and_company(customer_id, company_id)
        for item in items:
            await self._session.delete(item)
        await self._session.flush()

    async def clear_all(self, customer_id: int) -> None:
        """Очистить все корзины покупателя."""
        items = await self.list_by_customer(customer_id)
        for item in items:
            await self._session.delete(item)
        await self._session.flush()


class CatalogReadRepository:
    """Read-only доступ к таблицам business_service из единой БД."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_catalog_item(self, catalog_item_id: int) -> dict | None:
        """Возвращает name, price, company_id, is_active и блюдо Goden из catalog_items."""
        from sqlalchemy import text
        result = await self._session.execute(
            text(
                "SELECT id, name, price, company_id, is_active, goden_dish_id "
                "FROM catalog_items WHERE id = :id"
            ),
            {"id": catalog_item_id},
        )
        row = result.mappings().one_or_none()
        return dict(row) if row else None
