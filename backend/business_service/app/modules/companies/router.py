from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, require_roles
from app.db.session import get_db
from app.modules.companies.repository import CompanyRepository
from app.modules.companies.schemas import (
    CompanyCreate,
    CompanyListResponse,
    CompanyResponse,
    CompanyUpdate,
)
from app.modules.companies.service import CompanyService
from app.modules.users.models import User

router = APIRouter(prefix="/companies", tags=["Компании"])


def _get_service(session: Annotated[AsyncSession, Depends(get_db)]) -> CompanyService:
    return CompanyService(CompanyRepository(session))


@router.post("", response_model=CompanyResponse, status_code=201)
async def create_company(
    data: CompanyCreate,
    service: Annotated[CompanyService, Depends(_get_service)],
    current_user: Annotated[User, Depends(require_roles("owner"))],
):
    """Создание новой компании. Доступно только пользователям с ролью owner."""
    return await service.create(data, current_user)


@router.get("", response_model=CompanyListResponse)
async def list_companies(
    service: Annotated[CompanyService, Depends(_get_service)],
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    search: str | None = Query(default=None, description="Поиск по названию компании"),
):
    """Список всех компаний с пагинацией. При поиске кэш не используется."""
    return await service.list_companies(offset=offset, limit=limit, search=search)


@router.get("/my", response_model=list[CompanyResponse])
async def get_my_companies(
    service: Annotated[CompanyService, Depends(_get_service)],
    current_user: Annotated[User, Depends(require_roles("owner"))],
):
    """Все компании текущего владельца."""
    return await service.get_my_companies(current_user)


@router.get("/{company_id}", response_model=CompanyResponse)
async def get_company(
    company_id: int,
    service: Annotated[CompanyService, Depends(_get_service)],
):
    """Получить компанию по ID."""
    return await service.get_by_id(company_id)


@router.patch("/{company_id}", response_model=CompanyResponse)
async def update_company(
    company_id: int,
    data: CompanyUpdate,
    service: Annotated[CompanyService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Обновить данные компании. Доступно владельцу компании или moderator."""
    return await service.update(company_id, data, current_user)


@router.delete("/{company_id}", status_code=204)
async def delete_company(
    company_id: int,
    service: Annotated[CompanyService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Удалить компанию. Доступно владельцу компании или moderator."""
    await service.delete(company_id, current_user)


@router.post("/{company_id}/block", response_model=CompanyResponse)
async def block_company(
    company_id: int,
    service: Annotated[CompanyService, Depends(_get_service)],
    current_user: Annotated[User, Depends(require_roles("moderator"))],
):
    """Заблокировать компанию. Доступно только moderator."""
    return await service.block(company_id, current_user)


@router.post("/{company_id}/unblock", response_model=CompanyResponse)
async def unblock_company(
    company_id: int,
    service: Annotated[CompanyService, Depends(_get_service)],
    current_user: Annotated[User, Depends(require_roles("moderator"))],
):
    """Разблокировать компанию. Доступно только moderator."""
    return await service.unblock(company_id, current_user)
