from app.core.dependencies import TokenData
from app.modules.customers.exceptions import (
    AddressAccessDeniedError,
    AddressNotFoundError,
    PaymentMethodAccessDeniedError,
    PaymentMethodNotFoundError,
)
from app.modules.customers.repository import AddressRepository, PaymentMethodRepository
from app.modules.customers.schemas import (
    AddressCreate,
    AddressResponse,
    AddressUpdate,
    PaymentMethodCreate,
    PaymentMethodResponse,
)


class AddressService:
    def __init__(self, repo: AddressRepository) -> None:
        self._repo = repo

    async def list(self, current_user: TokenData) -> list[AddressResponse]:
        addresses = await self._repo.list_active(current_user.user_id)
        return [AddressResponse.model_validate(a) for a in addresses]

    async def create(self, current_user: TokenData, data: AddressCreate) -> AddressResponse:
        address = await self._repo.create(
            customer_id=current_user.user_id,
            **data.model_dump(),
        )
        return AddressResponse.model_validate(address)

    async def update(
        self, current_user: TokenData, address_id: int, data: AddressUpdate
    ) -> AddressResponse:
        address = await self._repo.get_by_id(address_id)
        if not address:
            raise AddressNotFoundError()
        if address.customer_id != current_user.user_id:
            raise AddressAccessDeniedError()

        updated = await self._repo.update(
            address, **{k: v for k, v in data.model_dump().items() if v is not None}
        )
        return AddressResponse.model_validate(updated)

    async def delete(self, current_user: TokenData, address_id: int) -> None:
        address = await self._repo.get_by_id(address_id)
        if not address:
            raise AddressNotFoundError()
        if address.customer_id != current_user.user_id:
            raise AddressAccessDeniedError()
        await self._repo.soft_delete(address)


class PaymentMethodService:
    def __init__(self, repo: PaymentMethodRepository) -> None:
        self._repo = repo

    async def list(self, current_user: TokenData) -> list[PaymentMethodResponse]:
        methods = await self._repo.list_active(current_user.user_id)
        return [PaymentMethodResponse.model_validate(m) for m in methods]

    async def create(
        self, current_user: TokenData, data: PaymentMethodCreate
    ) -> PaymentMethodResponse:
        method = await self._repo.create(
            customer_id=current_user.user_id,
            type=data.type,
            title=data.title,
        )
        return PaymentMethodResponse.model_validate(method)

    async def set_default(
        self, current_user: TokenData, method_id: int
    ) -> PaymentMethodResponse:
        method = await self._repo.get_by_id(method_id)
        if not method:
            raise PaymentMethodNotFoundError()
        if method.customer_id != current_user.user_id:
            raise PaymentMethodAccessDeniedError()

        # Снимаем флаг со всех, затем ставим на нужный
        await self._repo.clear_defaults(current_user.user_id)
        updated = await self._repo.set_default(method)
        return PaymentMethodResponse.model_validate(updated)

    async def delete(self, current_user: TokenData, method_id: int) -> None:
        method = await self._repo.get_by_id(method_id)
        if not method:
            raise PaymentMethodNotFoundError()
        if method.customer_id != current_user.user_id:
            raise PaymentMethodAccessDeniedError()
        await self._repo.soft_delete(method)
