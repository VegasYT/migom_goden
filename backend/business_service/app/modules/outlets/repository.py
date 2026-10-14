import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.outlets.models import Outlet, OutletItemAvailability, OutletManager


class OutletRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, outlet_id: int) -> Outlet | None:
        result = await self._session.execute(
            select(Outlet).where(Outlet.id == outlet_id)
        )
        return result.scalar_one_or_none()

    async def list_by_goden_points(self, point_ids: list[uuid.UUID]) -> list[Outlet]:
        result = await self._session.execute(select(Outlet).where(Outlet.goden_point_id.in_(point_ids)))
        return list(result.scalars().all())

    async def list_by_company(self, company_id: int) -> list[Outlet]:
        result = await self._session.execute(
            select(Outlet).where(Outlet.company_id == company_id)
        )
        return list(result.scalars().all())

    async def create(
        self,
        company_id: int,
        name: str,
        address: str,
        latitude: float,
        longitude: float,
        delivery_fee: int,
        free_delivery_from: int | None,
        min_order_price: int | None,
    ) -> Outlet:
        outlet = Outlet(
            company_id=company_id,
            name=name,
            address=address,
            latitude=latitude,
            longitude=longitude,
            delivery_fee=delivery_fee,
            free_delivery_from=free_delivery_from,
            min_order_price=min_order_price,
        )
        self._session.add(outlet)
        await self._session.flush()
        return await self.get_by_id(outlet.id)

    async def update(self, outlet: Outlet, **fields) -> Outlet:
        for key, value in fields.items():
            if value is not None:
                setattr(outlet, key, value)
        await self._session.flush()
        await self._session.refresh(outlet)
        return outlet

    async def flush(self) -> None:
        await self._session.flush()

    async def delete(self, outlet: Outlet) -> None:
        await self._session.delete(outlet)
        await self._session.flush()

    # --- Доступность товаров на точке ---

    async def get_item_availability(
        self, outlet_id: int, catalog_item_id: int
    ) -> OutletItemAvailability | None:
        result = await self._session.execute(
            select(OutletItemAvailability).where(
                OutletItemAvailability.outlet_id == outlet_id,
                OutletItemAvailability.catalog_item_id == catalog_item_id,
            )
        )
        return result.scalar_one_or_none()

    async def set_item_availability(
        self,
        outlet_id: int,
        catalog_item_id: int,
        is_available: bool,
        stock_count: int | None,
    ) -> OutletItemAvailability:
        record = await self.get_item_availability(outlet_id, catalog_item_id)
        if record is None:
            record = OutletItemAvailability(
                outlet_id=outlet_id,
                catalog_item_id=catalog_item_id,
                is_available=is_available,
                stock_count=stock_count,
            )
            self._session.add(record)
        else:
            record.is_available = is_available
            record.stock_count = stock_count
        await self._session.flush()
        await self._session.refresh(record)
        return record

    async def list_availability(self, outlet_id: int) -> list[OutletItemAvailability]:
        result = await self._session.execute(
            select(OutletItemAvailability).where(
                OutletItemAvailability.outlet_id == outlet_id
            )
        )
        return list(result.scalars().all())

    # --- Менеджеры точек ---

    async def get_manager(self, outlet_id: int, user_id: int) -> OutletManager | None:
        result = await self._session.execute(
            select(OutletManager).where(
                OutletManager.outlet_id == outlet_id,
                OutletManager.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()

    async def list_managers(self, outlet_id: int) -> list[OutletManager]:
        result = await self._session.execute(
            select(OutletManager)
            .options(selectinload(OutletManager.user))
            .where(OutletManager.outlet_id == outlet_id)
            .order_by(OutletManager.created_at)
        )
        return list(result.scalars().all())

    async def add_manager(self, outlet_id: int, user_id: int, added_by: int) -> OutletManager:
        record = OutletManager(outlet_id=outlet_id, user_id=user_id, added_by=added_by)
        self._session.add(record)
        await self._session.flush()
        await self._session.refresh(record)
        return record

    async def remove_manager(self, record: OutletManager) -> None:
        await self._session.delete(record)
        await self._session.flush()

    async def get_unavailable_item_ids(self, outlet_id: int) -> set[int]:
        result = await self._session.execute(
            select(OutletItemAvailability.catalog_item_id).where(
                OutletItemAvailability.outlet_id == outlet_id,
                (
                    (OutletItemAvailability.is_available == False)  # noqa: E712
                    | (OutletItemAvailability.stock_count == 0)
                ),
            )
        )
        return set(result.scalars().all())
