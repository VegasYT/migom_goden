from collections import defaultdict

from app.core.cache import cache_delete, cache_get, cache_set
from app.core.storage import delete_photo, upload_photo
from app.modules.catalog.exceptions import (
    CategoryAccessDeniedError,
    CategoryNotFoundError,
    CompanyNotFoundError,
    ItemAccessDeniedError,
    ItemNotFoundError,
)
from app.modules.catalog.repository import CatalogRepository
from app.modules.catalog.schemas import (
    CatalogItemCreate,
    CatalogItemResponse,
    CatalogItemUpdate,
    CategoryCreate,
    CategoryResponse,
    CategoryUpdate,
    CategoryWithItemsResponse,
    CompanyMenuResponse,
)
from app.modules.companies.repository import CompanyRepository
from app.modules.users.models import User

_MENU_CACHE_KEY = "menu:{company_id}"
_MENU_CACHE_TTL = 300  # 5 минут


class CatalogService:
    def __init__(self, repo: CatalogRepository, company_repo: CompanyRepository) -> None:
        self._repo = repo
        self._company_repo = company_repo

    # --- Меню компании ---

    async def get_menu(self, company_id: int) -> CompanyMenuResponse:
        cached = await cache_get(_MENU_CACHE_KEY.format(company_id=company_id))
        if cached:
            return CompanyMenuResponse(**cached)

        items = await self._repo.list_items_with_categories(company_id)

        # Группируем items по категории
        grouped: dict[int, tuple] = {}
        for item in items:
            cat = item.category
            if cat.id not in grouped:
                grouped[cat.id] = (cat, [])
            grouped[cat.id][1].append(CatalogItemResponse.model_validate(item))

        categories = [
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

        response = CompanyMenuResponse(company_id=company_id, categories=categories)
        await cache_set(
            _MENU_CACHE_KEY.format(company_id=company_id),
            response.model_dump(mode="json"),
            ttl=_MENU_CACHE_TTL,
        )
        return response

    # --- Глобальные категории (только модератор) ---

    async def list_categories(self, current_user: User, search: str | None = None) -> list[CategoryResponse]:
        is_moderator = current_user.role.name == "moderator"
        if is_moderator:
            categories = await self._repo.list_categories_all(search=search)
        else:
            categories = await self._repo.list_categories(search=search)
        return [CategoryResponse.model_validate(c) for c in categories]

    async def list_categories_public(self, search: str | None = None) -> list[CategoryResponse]:
        """Публичный список активных категорий - для выбора при создании позиции."""
        categories = await self._repo.list_categories(search=search)
        return [CategoryResponse.model_validate(c) for c in categories]

    async def create_category(self, data: CategoryCreate, current_user: User) -> CategoryResponse:
        self._require_moderator(current_user)
        category = await self._repo.create_category(
            name=data.name, emoji=data.emoji, sort_order=data.sort_order
        )
        return CategoryResponse.model_validate(category)

    async def update_category(
        self, category_id: int, data: CategoryUpdate, current_user: User
    ) -> CategoryResponse:
        self._require_moderator(current_user)
        category = await self._repo.get_category_by_id(category_id)
        if not category:
            raise CategoryNotFoundError()
        updated = await self._repo.update_category(
            category,
            name=data.name,
            emoji=data.emoji,
            sort_order=data.sort_order,
            is_active=data.is_active,
        )
        return CategoryResponse.model_validate(updated)

    async def delete_category(self, category_id: int, current_user: User) -> None:
        self._require_moderator(current_user)
        category = await self._repo.get_category_by_id(category_id)
        if not category:
            raise CategoryNotFoundError()
        await self._repo.delete_category(category)

    # --- Позиции меню ---

    async def create_item(
        self, company_id: int, data: CatalogItemCreate, current_user: User
    ) -> CatalogItemResponse:
        await self._check_company_access(company_id, current_user)
        # Проверяем что категория существует
        category = await self._repo.get_category_by_id(data.category_id)
        if not category:
            raise CategoryNotFoundError()
        item = await self._repo.create_item(
            company_id=company_id,
            category_id=data.category_id,
            name=data.name,
            price=float(data.price),
            description=data.description,
        )
        await self._invalidate_menu(company_id)
        return CatalogItemResponse.model_validate(item)

    async def update_item(
        self, company_id: int, item_id: int, data: CatalogItemUpdate, current_user: User
    ) -> CatalogItemResponse:
        await self._check_company_access(company_id, current_user)
        item = await self._repo.get_item_by_id(item_id)
        if not item:
            raise ItemNotFoundError()
        if item.company_id != company_id:
            raise ItemAccessDeniedError()

        if data.category_id is not None:
            category = await self._repo.get_category_by_id(data.category_id)
            if not category:
                raise CategoryNotFoundError()

        updated = await self._repo.update_item(
            item,
            category_id=data.category_id,
            name=data.name,
            description=data.description,
            price=float(data.price) if data.price else None,
            is_active=data.is_active,
        )
        await self._invalidate_menu(company_id)
        return CatalogItemResponse.model_validate(updated)

    async def delete_item(
        self, company_id: int, item_id: int, current_user: User
    ) -> None:
        await self._check_company_access(company_id, current_user)
        item = await self._repo.get_item_by_id(item_id)
        if not item:
            raise ItemNotFoundError()
        if item.company_id != company_id:
            raise ItemAccessDeniedError()

        if item.photo_url:
            await delete_photo(item.photo_url)

        await self._repo.delete_item(item)
        await self._invalidate_menu(company_id)

    async def upload_item_photo(
        self, company_id: int, item_id: int, data: bytes, content_type: str, current_user: User
    ) -> CatalogItemResponse:
        await self._check_company_access(company_id, current_user)
        item = await self._repo.get_item_by_id(item_id)
        if not item:
            raise ItemNotFoundError()
        if item.company_id != company_id:
            raise ItemAccessDeniedError()

        if item.photo_url:
            await delete_photo(item.photo_url)

        photo_url = await upload_photo(data, content_type, prefix="items")
        updated = await self._repo.update_item(item, photo_url=photo_url)
        await self._invalidate_menu(company_id)
        return CatalogItemResponse.model_validate(updated)

    # --- Вспомогательные ---

    def _require_moderator(self, current_user: User) -> None:
        if current_user.role.name != "moderator":
            raise CategoryAccessDeniedError()

    async def _check_company_access(self, company_id: int, current_user: User) -> None:
        if current_user.role.name == "moderator":
            return
        company = await self._company_repo.get_by_id(company_id)
        if not company:
            raise CompanyNotFoundError()
        if company.owner_id != current_user.id:
            raise CategoryAccessDeniedError()

    async def _invalidate_menu(self, company_id: int) -> None:
        await cache_delete(_MENU_CACHE_KEY.format(company_id=company_id))
