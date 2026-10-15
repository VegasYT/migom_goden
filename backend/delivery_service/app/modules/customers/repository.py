from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.customers.models import CustomerAddress, CustomerPaymentMethod, PaymentMethodType


class AddressRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, address_id: int) -> CustomerAddress | None:
        result = await self._session.execute(
            select(CustomerAddress).where(CustomerAddress.id == address_id)
        )
        return result.scalar_one_or_none()

    async def list_active(self, customer_id: int) -> list[CustomerAddress]:
        result = await self._session.execute(
            select(CustomerAddress).where(
                CustomerAddress.customer_id == customer_id,
                CustomerAddress.is_active == True,  # noqa: E712
            ).order_by(CustomerAddress.created_at.desc())
        )
        return list(result.scalars().all())

    async def create(self, customer_id: int, **fields) -> CustomerAddress:
        address = CustomerAddress(customer_id=customer_id, **fields)
        self._session.add(address)
        await self._session.flush()
        await self._session.refresh(address)
        return address

    async def update(self, address: CustomerAddress, /, **fields) -> CustomerAddress:
        # address - позиционный: у адреса есть поле с тем же именем
        for key, value in fields.items():
            if value is not None:
                setattr(address, key, value)
        await self._session.flush()
        return address

    async def soft_delete(self, address: CustomerAddress) -> None:
        address.is_active = False
        await self._session.flush()


class PaymentMethodRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, method_id: int) -> CustomerPaymentMethod | None:
        result = await self._session.execute(
            select(CustomerPaymentMethod).where(CustomerPaymentMethod.id == method_id)
        )
        return result.scalar_one_or_none()

    async def list_active(self, customer_id: int) -> list[CustomerPaymentMethod]:
        result = await self._session.execute(
            select(CustomerPaymentMethod).where(
                CustomerPaymentMethod.customer_id == customer_id,
                CustomerPaymentMethod.is_active == True,  # noqa: E712
            ).order_by(CustomerPaymentMethod.created_at.desc())
        )
        return list(result.scalars().all())

    async def create(
        self, customer_id: int, type: PaymentMethodType, title: str
    ) -> CustomerPaymentMethod:
        method = CustomerPaymentMethod(
            customer_id=customer_id,
            type=type,
            title=title,
            # Заглушки провайдера - не используются реально
            provider="stub_provider",
            provider_token="stub_token",
        )
        self._session.add(method)
        await self._session.flush()
        await self._session.refresh(method)
        return method

    async def clear_defaults(self, customer_id: int) -> None:
        """Снимает флаг is_default со всех методов покупателя."""
        methods = await self.list_active(customer_id)
        for m in methods:
            m.is_default = False
        await self._session.flush()

    async def set_default(self, method: CustomerPaymentMethod) -> CustomerPaymentMethod:
        method.is_default = True
        await self._session.flush()
        return method

    async def soft_delete(self, method: CustomerPaymentMethod) -> None:
        method.is_active = False
        if method.is_default:
            method.is_default = False
        await self._session.flush()
