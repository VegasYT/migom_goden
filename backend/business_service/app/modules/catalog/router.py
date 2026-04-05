from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.modules.catalog.repository import CatalogRepository
from app.modules.companies.repository import CompanyRepository
from app.modules.catalog.schemas import (
    CatalogItemCreate,
    CatalogItemResponse,
    CatalogItemUpdate,
    CategoryCreate,
    CategoryResponse,
    CategoryUpdate,
    CompanyMenuResponse,
)
from app.modules.catalog.service import CatalogService
from app.modules.users.models import User

router = APIRouter(tags=["Каталог(меню)"])

_ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}


def _get_service(session: Annotated[AsyncSession, Depends(get_db)]) -> CatalogService:
    return CatalogService(CatalogRepository(session), CompanyRepository(session))


# --- Глобальные категории ---

@router.get("/categories", response_model=list[CategoryResponse])
async def list_categories_public(
    service: Annotated[CatalogService, Depends(_get_service)],
    search: str | None = Query(default=None, description="Поиск по названию категории"),
):
    """Публичный список активных глобальных категорий. Используется при создании позиции меню."""
    return await service.list_categories_public(search=search)


@router.get("/categories/all", response_model=list[CategoryResponse])
async def list_categories_all(
    service: Annotated[CatalogService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
    search: str | None = Query(default=None, description="Поиск по названию категории"),
):
    """Все категории включая неактивные. Только для модератора."""
    return await service.list_categories(current_user, search=search)


@router.post("/categories", response_model=CategoryResponse, status_code=201)
async def create_category(
    data: CategoryCreate,
    service: Annotated[CatalogService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Создать глобальную категорию. Только для модератора."""
    return await service.create_category(data, current_user)


@router.patch("/categories/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: int,
    data: CategoryUpdate,
    service: Annotated[CatalogService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Обновить глобальную категорию. Только для модератора."""
    return await service.update_category(category_id, data, current_user)


@router.delete("/categories/{category_id}", status_code=204)
async def delete_category(
    category_id: int,
    service: Annotated[CatalogService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Удалить глобальную категорию. Только для модератора."""
    await service.delete_category(category_id, current_user)


# --- Меню компании ---

@router.get("/companies/{company_id}/menu", response_model=CompanyMenuResponse)
async def get_menu(
    company_id: int,
    service: Annotated[CatalogService, Depends(_get_service)],
):
    """Получить полное меню компании: позиции сгруппированные по глобальным категориям. Кэшируется на 5 минут."""
    return await service.get_menu(company_id)


# --- Позиции меню ---

@router.post("/companies/{company_id}/items", response_model=CatalogItemResponse, status_code=201)
async def create_item(
    company_id: int,
    data: CatalogItemCreate,
    service: Annotated[CatalogService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Создать позицию меню. category_id выбирается из глобального списка GET /categories. Доступно владельцу компании."""
    return await service.create_item(company_id, data, current_user)


@router.patch("/companies/{company_id}/items/{item_id}", response_model=CatalogItemResponse)
async def update_item(
    company_id: int,
    item_id: int,
    data: CatalogItemUpdate,
    service: Annotated[CatalogService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Обновить позицию меню. Доступно владельцу компании."""
    return await service.update_item(company_id, item_id, data, current_user)


@router.delete("/companies/{company_id}/items/{item_id}", status_code=204)
async def delete_item(
    company_id: int,
    item_id: int,
    service: Annotated[CatalogService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Удалить позицию меню. Если есть фото - удаляется из MinIO. Доступно владельцу компании."""
    await service.delete_item(company_id, item_id, current_user)


@router.post("/companies/{company_id}/items/{item_id}/photo", response_model=CatalogItemResponse)
async def upload_item_photo(
    company_id: int,
    item_id: int,
    file: Annotated[UploadFile, File()],
    service: Annotated[CatalogService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Загрузить фото для позиции меню. Допустимые форматы: JPEG, PNG, WebP. Старое фото заменяется."""
    if file.content_type not in _ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Допустимые форматы: {', '.join(_ALLOWED_IMAGE_TYPES)}",
        )
    data = await file.read()
    return await service.upload_item_photo(company_id, item_id, data, file.content_type, current_user)
