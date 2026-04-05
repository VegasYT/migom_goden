from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import TokenData, require_roles
from app.db.session import get_db
from app.modules.customers.repository import AddressRepository, PaymentMethodRepository
from app.modules.customers.schemas import (
    AddressCreate,
    AddressResponse,
    AddressUpdate,
    PaymentMethodCreate,
    PaymentMethodResponse,
)
from app.modules.customers.service import AddressService, PaymentMethodService

router = APIRouter(tags=["Покупатели"])


def _get_address_service(session: Annotated[AsyncSession, Depends(get_db)]) -> AddressService:
    return AddressService(AddressRepository(session))


def _get_payment_service(session: Annotated[AsyncSession, Depends(get_db)]) -> PaymentMethodService:
    return PaymentMethodService(PaymentMethodRepository(session))


# --- Адреса ---

@router.get("/customers/me/addresses", response_model=list[AddressResponse])
async def list_addresses(
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[AddressService, Depends(_get_address_service)],
):
    """Список сохранённых адресов покупателя."""
    return await service.list(current_user)


@router.post("/customers/me/addresses", response_model=AddressResponse, status_code=201)
async def create_address(
    data: AddressCreate,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[AddressService, Depends(_get_address_service)],
):
    """Сохранить новый адрес доставки."""
    return await service.create(current_user, data)


@router.patch("/customers/me/addresses/{address_id}", response_model=AddressResponse)
async def update_address(
    address_id: int,
    data: AddressUpdate,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[AddressService, Depends(_get_address_service)],
):
    """Обновить сохранённый адрес."""
    return await service.update(current_user, address_id, data)


@router.delete("/customers/me/addresses/{address_id}", status_code=204)
async def delete_address(
    address_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[AddressService, Depends(_get_address_service)],
):
    """Удалить адрес (soft delete)."""
    await service.delete(current_user, address_id)


# --- Способы оплаты ---

@router.get("/customers/me/payment-methods", response_model=list[PaymentMethodResponse])
async def list_payment_methods(
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[PaymentMethodService, Depends(_get_payment_service)],
):
    """Список способов оплаты покупателя."""
    return await service.list(current_user)


@router.post("/customers/me/payment-methods", response_model=PaymentMethodResponse, status_code=201)
async def create_payment_method(
    data: PaymentMethodCreate,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[PaymentMethodService, Depends(_get_payment_service)],
):
    """Добавить способ оплаты. Провайдер - заглушка, реальные транзакции не выполняются."""
    return await service.create(current_user, data)


@router.patch(
    "/customers/me/payment-methods/{method_id}/set-default",
    response_model=PaymentMethodResponse,
)
async def set_default_payment_method(
    method_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[PaymentMethodService, Depends(_get_payment_service)],
):
    """Установить способ оплаты по умолчанию."""
    return await service.set_default(current_user, method_id)


@router.delete("/customers/me/payment-methods/{method_id}", status_code=204)
async def delete_payment_method(
    method_id: int,
    current_user: Annotated[TokenData, Depends(require_roles("customer"))],
    service: Annotated[PaymentMethodService, Depends(_get_payment_service)],
):
    """Удалить способ оплаты (soft delete)."""
    await service.delete(current_user, method_id)
