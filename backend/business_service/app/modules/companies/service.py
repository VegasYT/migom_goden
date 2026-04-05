from app.core.cache import cache_delete, cache_get, cache_set
from app.modules.companies.exceptions import (
    CompanyAccessDeniedError,
    CompanyBlockedError,
    CompanyNotFoundError,
)
from app.modules.companies.repository import CompanyRepository
from app.modules.companies.schemas import (
    CompanyCreate,
    CompanyListResponse,
    CompanyResponse,
    CompanyUpdate,
)
from app.modules.users.models import User

_CACHE_KEY = "companies:list"
_CACHE_TTL = 300  # 5 минут


class CompanyService:
    def __init__(self, repo: CompanyRepository) -> None:
        self._repo = repo

    async def create(self, data: CompanyCreate, current_user: User) -> CompanyResponse:
        company = await self._repo.create(
            owner_id=current_user.id,
            name=data.name,
            description=data.description,
        )
        await cache_delete(_CACHE_KEY)
        return CompanyResponse.model_validate(company)

    async def get_by_id(self, company_id: int) -> CompanyResponse:
        company = await self._repo.get_by_id(company_id)
        if not company:
            raise CompanyNotFoundError()
        return CompanyResponse.model_validate(company)

    async def list_companies(
        self, offset: int, limit: int, search: str | None = None
    ) -> CompanyListResponse:
        # Кэш только без поиска
        if not search:
            cached = await cache_get(_CACHE_KEY)
            if cached:
                return CompanyListResponse(**cached)

        companies, total = await self._repo.list_all(offset=offset, limit=limit, search=search)
        response = CompanyListResponse(
            items=[CompanyResponse.model_validate(c) for c in companies],
            total=total,
        )
        if not search:
            await cache_set(_CACHE_KEY, response.model_dump(mode="json"), ttl=_CACHE_TTL)
        return response

    async def get_my_companies(self, current_user: User) -> list[CompanyResponse]:
        companies = await self._repo.get_by_owner(current_user.id)
        return [CompanyResponse.model_validate(c) for c in companies]

    async def update(
        self, company_id: int, data: CompanyUpdate, current_user: User
    ) -> CompanyResponse:
        company = await self._repo.get_by_id(company_id)
        if not company:
            raise CompanyNotFoundError()
        self._check_owner_or_admin(company, current_user)

        updated = await self._repo.update(
            company,
            name=data.name,
            description=data.description,
            is_active=data.is_active,
        )
        await cache_delete(_CACHE_KEY)
        return CompanyResponse.model_validate(updated)

    async def delete(self, company_id: int, current_user: User) -> None:
        company = await self._repo.get_by_id(company_id)
        if not company:
            raise CompanyNotFoundError()
        self._check_owner_or_admin(company, current_user)

        await self._repo.delete(company)
        await cache_delete(_CACHE_KEY)

    async def block(self, company_id: int, current_user: User) -> CompanyResponse:
        """Только moderator."""
        if current_user.role.name not in ("moderator"):
            raise CompanyAccessDeniedError()

        company = await self._repo.get_by_id(company_id)
        if not company:
            raise CompanyNotFoundError()

        updated = await self._repo.update(company, is_blocked=True)
        await cache_delete(_CACHE_KEY)
        return CompanyResponse.model_validate(updated)

    async def unblock(self, company_id: int, current_user: User) -> CompanyResponse:
        """Только moderator."""
        if current_user.role.name not in ("moderator"):
            raise CompanyAccessDeniedError()

        company = await self._repo.get_by_id(company_id)
        if not company:
            raise CompanyNotFoundError()

        updated = await self._repo.update(company, is_blocked=False)
        await cache_delete(_CACHE_KEY)
        return CompanyResponse.model_validate(updated)

    def _check_owner_or_admin(self, company, current_user: User) -> None:
        is_owner = company.owner_id == current_user.id
        is_privileged = current_user.role.name in ("moderator")
        if not is_owner and not is_privileged:
            raise CompanyAccessDeniedError()
        if company.is_blocked and not is_privileged:
            raise CompanyBlockedError()
