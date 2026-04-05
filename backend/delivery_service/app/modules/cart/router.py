from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import TokenData, require_roles
from app.db.session import get_db
from app.modules.cart.repository import CartRepository, CatalogReadRepository
from app.modules.cart.schemas import AllCartsResponse, CartItemAdd, CartItemUpdate, CartResponse
from app.modules.cart.service import CartService

router = APIRouter(tags=["Корзина"])


def _get_service(session: Annotated[AsyncSession, Depends(get_db)]) -> CartService:
    return CartService(
        cart_repo=CartRepository(session),
        catalog_repo=CatalogReadRepository(session),
    )


@router.get("/cart", response_model=AllCartsResponse)
async def get_all_carts(
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[CartService, Depends(_get_service)],
):
    """Все корзины покупателя, сгруппированные по компаниям."""
    return await service.get_all_carts(current_user)


@router.get("/cart/{company_id}", response_model=CartResponse)
async def get_cart(
    company_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[CartService, Depends(_get_service)],
):
    """Корзина покупателя для конкретной компании."""
    return await service.get_cart(current_user, company_id)


@router.post("/cart/items", response_model=CartResponse, status_code=201)
async def add_item(
    data: CartItemAdd,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[CartService, Depends(_get_service)],
):
    """Добавить товар в корзину. Если товар уже есть - количество суммируется.
    Товары из разных компаний помещаются в отдельные корзины."""
    return await service.add_item(current_user, data)


@router.patch("/cart/items/{item_id}", response_model=CartResponse)
async def update_item(
    item_id: int,
    data: CartItemUpdate,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[CartService, Depends(_get_service)],
):
    """Обновить количество позиции в корзине."""
    return await service.update_item(current_user, item_id, data)


@router.delete("/cart/items/{item_id}", status_code=204)
async def delete_item(
    item_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[CartService, Depends(_get_service)],
):
    """Удалить позицию из корзины."""
    await service.delete_item(current_user, item_id)


@router.delete("/cart/{company_id}", status_code=204)
async def clear_cart(
    company_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[CartService, Depends(_get_service)],
):
    """Очистить корзину конкретной компании."""
    await service.clear_cart(current_user, company_id)


@router.delete("/cart", status_code=204)
async def clear_all_carts(
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[CartService, Depends(_get_service)],
):
    """Очистить все корзины покупателя."""
    await service.clear_all_carts(current_user)
