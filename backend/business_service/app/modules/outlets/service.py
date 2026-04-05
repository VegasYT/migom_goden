from app.core.cache import cache_delete, cache_get, cache_set
from app.modules.catalog.repository import CatalogRepository
from app.modules.catalog.schemas import CatalogItemResponse, CategoryWithItemsResponse
from app.modules.companies.repository import CompanyRepository
from app.modules.outlets.exceptions import (
    InvalidManagerRoleError,
    ManagerAlreadyExistsError,
    ManagerNotFoundError,
    OutletAccessDeniedError,
    OutletNotFoundError,
)
from app.modules.outlets.repository import OutletRepository
from app.modules.outlets.schemas import (
    ItemAvailabilityResponse,
    ItemAvailabilityUpdate,
    ItemAvailabilityWithInfoResponse,
    OutletCreate,
    OutletManagerResponse,
    OutletMenuResponse,
    OutletResponse,
    OutletUpdate,
)
from app.modules.users.models import User


_OUTLET_MENU_CACHE_KEY = "outlet_menu:{outlet_id}"
_OUTLET_MENU_CACHE_TTL = 300  # 5 минут


class OutletService:
    def __init__(
        self,
        repo: OutletRepository,
        company_repo: CompanyRepository,
        catalog_repo: CatalogRepository,
    ) -> None:
        self._repo = repo
        self._company_repo = company_repo
        self._catalog_repo = catalog_repo

    async def list_outlets(self, company_id: int) -> list[OutletResponse]:
        outlets = await self._repo.list_by_company(company_id)
        return [OutletResponse.model_validate(o) for o in outlets]

    async def get_outlet(self, outlet_id: int) -> OutletResponse:
        outlet = await self._repo.get_by_id(outlet_id)
        if not outlet:
            raise OutletNotFoundError()
        return OutletResponse.model_validate(outlet)

    async def create_outlet(
        self, company_id: int, data: OutletCreate, current_user: User
    ) -> OutletResponse:
        await self._check_access(company_id, current_user)
        outlet = await self._repo.create(
            company_id=company_id,
            name=data.name,
            address=data.address,
            latitude=float(data.latitude),
            longitude=float(data.longitude),
            delivery_fee=data.delivery_fee,
            free_delivery_from=data.free_delivery_from,
            min_order_price=data.min_order_price,
        )
        return OutletResponse.model_validate(outlet)

    async def update_outlet(
        self, company_id: int, outlet_id: int, data: OutletUpdate, current_user: User
    ) -> OutletResponse:
        await self._check_access(company_id, current_user)
        outlet = await self._repo.get_by_id(outlet_id)
        if not outlet:
            raise OutletNotFoundError()
        if outlet.company_id != company_id:
            raise OutletAccessDeniedError()

        updated = await self._repo.update(
            outlet,
            name=data.name,
            address=data.address,
            latitude=float(data.latitude) if data.latitude is not None else None,
            longitude=float(data.longitude) if data.longitude is not None else None,
            is_active=data.is_active,
            delivery_fee=data.delivery_fee,
            free_delivery_from=data.free_delivery_from,
            min_order_price=data.min_order_price,
        )
        return OutletResponse.model_validate(updated)

    async def delete_outlet(
        self, company_id: int, outlet_id: int, current_user: User
    ) -> None:
        await self._check_access(company_id, current_user)
        outlet = await self._repo.get_by_id(outlet_id)
        if not outlet:
            raise OutletNotFoundError()
        if outlet.company_id != company_id:
            raise OutletAccessDeniedError()
        await self._repo.delete(outlet)

    async def get_outlet_menu(self, outlet_id: int) -> OutletMenuResponse:
        cached = await cache_get(_OUTLET_MENU_CACHE_KEY.format(outlet_id=outlet_id))
        if cached:
            return OutletMenuResponse(**cached)

        outlet = await self._repo.get_by_id(outlet_id)
        if not outlet:
            raise OutletNotFoundError()

        items = await self._catalog_repo.list_items_with_categories(outlet.company_id)
        unavailable_ids = await self._repo.get_unavailable_item_ids(outlet_id)

        grouped: dict[int, tuple] = {}
        for item in items:
            if item.id in unavailable_ids:
                continue
            cat = item.category
            if cat.id not in grouped:
                grouped[cat.id] = (cat, [])
            grouped[cat.id][1].append(CatalogItemResponse.model_validate(item))

        result_categories = [
            CategoryWithItemsResponse(
                id=cat.id,
                name=cat.name,
                emoji=cat.emoji,
                sort_order=cat.sort_order,
                is_active=cat.is_active,
                items=cat_items,
            )
            for cat, cat_items in sorted(grouped.values(), key=lambda x: x[0].sort_order)
        ]

        response = OutletMenuResponse(outlet_id=outlet_id, categories=result_categories)
        await cache_set(
            _OUTLET_MENU_CACHE_KEY.format(outlet_id=outlet_id),
            response.model_dump(mode="json"),
            ttl=_OUTLET_MENU_CACHE_TTL,
        )
        return response

    async def list_items_availability(
        self, outlet_id: int, current_user: User
    ) -> list[ItemAvailabilityWithInfoResponse]:
        outlet = await self._repo.get_by_id(outlet_id)
        if not outlet:
            raise OutletNotFoundError()
        await self._check_access(outlet.company_id, current_user)

        items = await self._catalog_repo.list_items_with_categories(outlet.company_id)
        # Строим словарь outlet_item_availability по catalog_item_id
        availability_records = await self._repo.list_availability(outlet_id)
        availability_map = {r.catalog_item_id: r for r in availability_records}

        return [
            ItemAvailabilityWithInfoResponse(
                catalog_item_id=item.id,
                name=item.name,
                is_available=availability_map[item.id].is_available
                if item.id in availability_map else True,
                stock_count=availability_map[item.id].stock_count
                if item.id in availability_map else None,
            )
            for item in items
        ]

    async def set_item_availability(
        self,
        outlet_id: int,
        catalog_item_id: int,
        data: ItemAvailabilityUpdate,
        current_user: User,
    ) -> ItemAvailabilityResponse:
        outlet = await self._repo.get_by_id(outlet_id)
        if not outlet:
            raise OutletNotFoundError()
        await self._check_access(outlet.company_id, current_user)

        is_available = data.is_available
        if data.stock_count is not None and data.stock_count == 0:
            is_available = False

        record = await self._repo.set_item_availability(
            outlet_id, catalog_item_id, is_available, data.stock_count
        )
        await cache_delete(_OUTLET_MENU_CACHE_KEY.format(outlet_id=outlet_id))
        return ItemAvailabilityResponse.model_validate(record)

    # --- Менеджеры ---

    async def list_managers(self, outlet_id: int, current_user: User) -> list[OutletManagerResponse]:
        outlet = await self._repo.get_by_id(outlet_id)
        if not outlet:
            raise OutletNotFoundError()
        await self._check_access(outlet.company_id, current_user)
        managers = await self._repo.list_managers(outlet_id)
        return [self._manager_to_response(m) for m in managers]

    async def add_manager(
        self, outlet_id: int, email: str, current_user: User
    ) -> OutletManagerResponse:
        outlet = await self._repo.get_by_id(outlet_id)
        if not outlet:
            raise OutletNotFoundError()
        await self._check_access(outlet.company_id, current_user)

        # Ищем пользователя по email и проверяем роль
        from app.modules.auth.repository import UserRepository
        user_repo = UserRepository(self._repo._session)
        target_user = await user_repo.get_by_email(email)
        if not target_user or target_user.role.name != "outlet_manager":
            raise InvalidManagerRoleError()

        user_id = target_user.id

        # Уже является менеджером?
        existing = await self._repo.get_manager(outlet_id, user_id)
        if existing:
            raise ManagerAlreadyExistsError()

        record = await self._repo.add_manager(outlet_id, user_id, current_user.id)
        # Перечитываем с relationship
        managers = await self._repo.list_managers(outlet_id)
        added = next(m for m in managers if m.id == record.id)
        return self._manager_to_response(added)

    async def remove_manager(self, outlet_id: int, user_id: int, current_user: User) -> None:
        outlet = await self._repo.get_by_id(outlet_id)
        if not outlet:
            raise OutletNotFoundError()
        await self._check_access(outlet.company_id, current_user)

        record = await self._repo.get_manager(outlet_id, user_id)
        if not record:
            raise ManagerNotFoundError()
        await self._repo.remove_manager(record)

    def _manager_to_response(self, m) -> OutletManagerResponse:
        return OutletManagerResponse(
            id=m.id,
            outlet_id=m.outlet_id,
            user_id=m.user_id,
            user_full_name=m.user.full_name,
            user_email=m.user.email,
            added_by=m.added_by,
            created_at=m.created_at.isoformat(),
        )

    async def _check_access(self, company_id: int, current_user: User) -> None:
        is_privileged = current_user.role.name == "moderator"
        if is_privileged:
            return
        company = await self._company_repo.get_by_id(company_id)
        if not company or company.owner_id != current_user.id:
            raise OutletAccessDeniedError()
