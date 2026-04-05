from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import TokenData, require_roles
from app.db.session import get_db
from app.modules.cart.repository import CartRepository, CatalogReadRepository
from app.modules.couriers.repository import CourierRepository
from app.modules.orders.repository import OrderRepository, OutletReadRepository
from app.modules.orders.schemas import (
    OrderCreate,
    OrderFilters,
    OrderListResponse,
    OrderResponse,
    OrderStatus,
    SortField,
    SortOrder,
)
from app.modules.orders.service import OrderService
from app.modules.shifts.repository import ShiftRepository

router = APIRouter()


def _get_service(request: Request, session: Annotated[AsyncSession, Depends(get_db)]) -> OrderService:
    return OrderService(
        order_repo=OrderRepository(session),
        outlet_repo=OutletReadRepository(session),
        cart_repo=CartRepository(session),
        catalog_repo=CatalogReadRepository(session),
        courier_repo=CourierRepository(session),
        shift_repo=ShiftRepository(session),
        redis=request.app.state.redis,
    )


# --- Покупатель ---

@router.post("/orders", response_model=OrderResponse, status_code=201, tags=["Заказы - покупатель"])
async def create_order(
    data: OrderCreate,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Оформить заказ из корзины. Корзина очищается после успешного создания."""
    return await service.create_order(current_user, data)


@router.get("/orders", response_model=OrderListResponse, tags=["Заказы - покупатель"])
async def get_my_orders(
    offset: int = 0,
    limit: int = 20,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))] = None,
    service: Annotated[OrderService, Depends(_get_service)] = None,
):
    """История заказов текущего покупателя."""
    return await service.get_my_orders(current_user, offset=offset, limit=limit)


@router.get("/orders/{order_id}", response_model=OrderResponse, tags=["Заказы - покупатель"])
async def get_order(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Детали заказа покупателя."""
    return await service.get_order(current_user, order_id)


@router.post("/orders/{order_id}/cancel", response_model=OrderResponse, tags=["Заказы - покупатель"])
async def customer_cancel(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Отменить заказ. Только из статуса 'new'."""
    return await service.customer_cancel(current_user, order_id)


@router.post("/orders/{order_id}/receive", response_model=OrderResponse, tags=["Заказы - покупатель"])
async def customer_receive(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Подтвердить получение при самовывозе: ready_for_pickup → received."""
    return await service.customer_receive(current_user, order_id)


@router.post("/orders/{order_id}/confirm", response_model=OrderResponse, tags=["Заказы - покупатель"])
async def customer_confirm(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Подтвердить получение доставки: delivered → received."""
    return await service.customer_confirm(current_user, order_id)


# --- Курьер ---

@router.get("/courier/orders/available", response_model=list[OrderResponse], tags=["Заказы - курьер"])
async def get_available_orders(
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Новые заказы доступные курьеру (адрес в его геозоне)."""
    return await service.get_available_orders(current_user)


@router.get("/courier/orders/active", response_model=OrderResponse, tags=["Заказы - курьер"])
async def get_active_order(
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Текущий активный заказ курьера."""
    return await service.get_active_order(current_user)


@router.post("/courier/orders/{order_id}/accept", response_model=OrderResponse, tags=["Заказы - курьер"])
async def courier_accept(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Принять заказ: new → assigned. Курьер должен быть в смене и без активного заказа."""
    return await service.courier_accept(current_user, order_id)


@router.post("/courier/orders/{order_id}/reject", status_code=204, tags=["Заказы - курьер"])
async def courier_reject(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Отказаться от предложенного заказа. Система предложит его следующему курьеру."""
    await service.courier_reject(current_user, order_id)


@router.post("/courier/orders/{order_id}/pickup", response_model=OrderResponse, tags=["Заказы - курьер"])
async def courier_pickup(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Курьер забрал заказ из точки: ready_for_pickup → in_delivery."""
    return await service.courier_pickup(current_user, order_id)


@router.post("/courier/orders/{order_id}/deliver", response_model=OrderResponse, tags=["Заказы - курьер"])
async def courier_deliver(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("courier"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Курьер доставил заказ: in_delivery → delivered."""
    return await service.courier_deliver(current_user, order_id)


# --- Владелец ---

@router.get("/outlet/orders", response_model=OrderListResponse, tags=["Заказы - владелец/менеджер"])
async def get_outlet_orders(
    offset: int = 0,
    limit: int = 20,
    status: OrderStatus | None = Query(default=None),
    date_from: datetime | None = Query(default=None),
    date_to: datetime | None = Query(default=None),
    sort_by: SortField = Query(default=SortField.created_at),
    sort_order: SortOrder = Query(default=SortOrder.desc),
    current_user: Annotated[TokenData, Depends(require_roles("owner", "outlet_manager"))] = None,
    service: Annotated[OrderService, Depends(_get_service)] = None,
):
    """Заказы по точкам владельца или менеджера. Фильтры: статус, дата. Сортировка: по дате или цене."""
    filters = OrderFilters(
        status=status, date_from=date_from, date_to=date_to,
        sort_by=sort_by, sort_order=sort_order,
    )
    return await service.get_outlet_orders(current_user, filters, offset=offset, limit=limit)


@router.post("/outlet/orders/{order_id}/assemble", response_model=OrderResponse, tags=["Заказы - владелец/менеджер"])
async def owner_assemble(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("owner", "outlet_manager"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Начать сборку заказа: assigned → assembling."""
    return await service.owner_assemble(current_user, order_id)


@router.post("/outlet/orders/{order_id}/ready", response_model=OrderResponse, tags=["Заказы - владелец/менеджер"])
async def owner_ready(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("owner", "outlet_manager"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Заказ собран и готов к выдаче: assembling → ready_for_pickup."""
    return await service.owner_ready(current_user, order_id)


@router.post("/outlet/orders/{order_id}/cancel", response_model=OrderResponse, tags=["Заказы - владелец/менеджер"])
async def owner_cancel(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("owner", "outlet_manager"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Отменить заказ. Освобождает курьера если был назначен."""
    return await service.owner_cancel(current_user, order_id)


# --- Модератор ---

@router.get("/admin/orders", response_model=OrderListResponse, tags=["Заказы - модератор"])
async def admin_list_orders(
    offset: int = 0,
    limit: int = 20,
    status: OrderStatus | None = Query(default=None),
    outlet_id: int | None = Query(default=None),
    outlet_ids: list[int] | None = Query(default=None, description="Фильтр по нескольким точкам"),
    search: str | None = Query(default=None, description="Поиск по ID заказа или комментарию"),
    date_from: datetime | None = Query(default=None),
    date_to: datetime | None = Query(default=None),
    sort_by: SortField = Query(default=SortField.created_at),
    sort_order: SortOrder = Query(default=SortOrder.desc),
    current_user: Annotated[TokenData, Depends(require_roles("moderator"))] = None,
    service: Annotated[OrderService, Depends(_get_service)] = None,
):
    """Все заказы. Фильтры: статус, точка/точки, поиск, дата. Сортировка: created_at, total_price, id."""
    filters = OrderFilters(
        status=status,
        outlet_id=outlet_id,
        outlet_ids=outlet_ids,
        search=search,
        date_from=date_from,
        date_to=date_to,
        sort_by=sort_by,
        sort_order=sort_order,
    )
    return await service.admin_list_orders(filters, offset=offset, limit=limit)


@router.post("/admin/orders/{order_id}/assign/{courier_id}", response_model=OrderResponse, tags=["Заказы - модератор"])
async def admin_assign(
    order_id: int,
    courier_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("moderator"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Ручное назначение курьера модератором."""
    return await service.admin_assign(current_user, order_id, courier_id)


@router.post("/admin/orders/{order_id}/cancel", response_model=OrderResponse, tags=["Заказы - модератор"])
async def admin_cancel(
    order_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("moderator"))],
    service: Annotated[OrderService, Depends(_get_service)],
):
    """Принудительная отмена заказа модератором."""
    return await service.admin_cancel(current_user, order_id)
