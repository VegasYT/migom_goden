from collections import defaultdict
from decimal import Decimal

from app.core.dependencies import TokenData
from app.modules.cart.exceptions import (
    CartItemAccessDeniedError,
    CartItemNotFoundError,
    CartNotFoundError,
    CatalogItemNotFoundError,
)
from app.modules.cart.repository import CartRepository, CatalogReadRepository
from app.modules.cart.schemas import (
    AllCartsResponse,
    CartItemAdd,
    CartItemResponse,
    CartItemUpdate,
    CartResponse,
)


class CartService:
    def __init__(self, cart_repo: CartRepository, catalog_repo: CatalogReadRepository) -> None:
        self._cart = cart_repo
        self._catalog = catalog_repo

    async def _build_cart_response(self, company_id: int, items: list) -> CartResponse:
        """Собирает CartResponse для одной компании."""
        result = []
        total = Decimal("0.00")
        for item in items:
            catalog = await self._catalog.get_catalog_item(item.catalog_item_id)
            if not catalog:
                continue
            price = Decimal(str(catalog["price"]))
            subtotal = price * item.quantity
            total += subtotal
            result.append(CartItemResponse(
                id=item.id,
                catalog_item_id=item.catalog_item_id,
                company_id=item.company_id,
                name=catalog["name"],
                price=price,
                quantity=item.quantity,
                subtotal=subtotal,
                added_at=item.added_at,
            ))
        return CartResponse(company_id=company_id, items=result, total=total)

    async def get_all_carts(self, current_user: TokenData) -> AllCartsResponse:
        """Все корзины покупателя, сгруппированные по компаниям."""
        all_items = await self._cart.list_by_customer(current_user.user_id)

        # Группируем по company_id
        by_company: dict[int, list] = defaultdict(list)
        for item in all_items:
            by_company[item.company_id].append(item)

        carts = []
        grand_total = Decimal("0.00")
        for company_id, items in by_company.items():
            cart = await self._build_cart_response(company_id, items)
            carts.append(cart)
            grand_total += cart.total

        return AllCartsResponse(carts=carts, grand_total=grand_total)

    async def get_cart(self, current_user: TokenData, company_id: int) -> CartResponse:
        """Корзина покупателя для конкретной компании."""
        items = await self._cart.list_by_customer_and_company(current_user.user_id, company_id)
        if not items:
            raise CartNotFoundError()
        return await self._build_cart_response(company_id, items)

    async def add_item(self, current_user: TokenData, data: CartItemAdd) -> CartResponse:
        catalog = await self._catalog.get_catalog_item(data.catalog_item_id)
        if not catalog or not catalog["is_active"]:
            raise CatalogItemNotFoundError()

        company_id = catalog["company_id"]

        # Если товар уже в корзине - увеличиваем количество
        existing = await self._cart.get_existing(current_user.user_id, data.catalog_item_id)
        if existing:
            await self._cart.update_quantity(existing, existing.quantity + data.quantity)
        else:
            await self._cart.add(
                customer_id=current_user.user_id,
                company_id=company_id,
                catalog_item_id=data.catalog_item_id,
                quantity=data.quantity,
            )

        return await self.get_cart(current_user, company_id)

    async def update_item(
        self, current_user: TokenData, item_id: int, data: CartItemUpdate
    ) -> CartResponse:
        item = await self._cart.get_item_by_id(item_id)
        if not item:
            raise CartItemNotFoundError()
        if item.customer_id != current_user.user_id:
            raise CartItemAccessDeniedError()

        await self._cart.update_quantity(item, data.quantity)
        return await self.get_cart(current_user, item.company_id)

    async def delete_item(self, current_user: TokenData, item_id: int) -> None:
        item = await self._cart.get_item_by_id(item_id)
        if not item:
            raise CartItemNotFoundError()
        if item.customer_id != current_user.user_id:
            raise CartItemAccessDeniedError()
        await self._cart.delete(item)

    async def clear_cart(self, current_user: TokenData, company_id: int) -> None:
        """Очистить корзину конкретной компании."""
        await self._cart.clear_company(current_user.user_id, company_id)

    async def clear_all_carts(self, current_user: TokenData) -> None:
        """Очистить все корзины покупателя."""
        await self._cart.clear_all(current_user.user_id)
