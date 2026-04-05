from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.modules.users.repository import UsersRepository
from app.modules.users.schemas import (
    ChangePasswordRequest,
    UserListResponse,
    UserResponse,
    UserUpdateMe,
)
from app.modules.users.service import UsersService
from app.modules.users.models import User

router = APIRouter(prefix="/users", tags=["Пользователи"])


def _get_service(session: Annotated[AsyncSession, Depends(get_db)]) -> UsersService:
    return UsersService(UsersRepository(session))


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Получить профиль текущего авторизованного пользователя."""
    return UserResponse.model_validate(current_user)


@router.patch("/me", response_model=UserResponse)
async def update_me(
    data: UserUpdateMe,
    service: Annotated[UsersService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Обновить имя или телефон текущего пользователя."""
    return await service.update_me(current_user, data)


_ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}


@router.post("/me/avatar", response_model=UserResponse)
async def upload_avatar(
    file: Annotated[UploadFile, File()],
    service: Annotated[UsersService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Загрузить аватар пользователя. Допустимые форматы: JPEG, PNG, WebP. Старый аватар заменяется."""
    if file.content_type not in _ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Допустимые форматы: {', '.join(_ALLOWED_IMAGE_TYPES)}",
        )
    data = await file.read()
    return await service.upload_avatar(current_user, data, file.content_type)


@router.post("/me/change-password", status_code=204)
async def change_password(
    data: ChangePasswordRequest,
    service: Annotated[UsersService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Сменить пароль. Требует указать текущий пароль для подтверждения."""
    await service.change_password(current_user, data)


@router.get("", response_model=UserListResponse)
async def list_users(
    service: Annotated[UsersService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    """Список всех пользователей с пагинацией. Доступно только moderator."""
    return await service.list_users(offset=offset, limit=limit, current_user=current_user)


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    service: Annotated[UsersService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Получить профиль пользователя по ID. Доступно только moderator."""
    return await service.get_user(user_id, current_user)


@router.post("/{user_id}/block", response_model=UserResponse)
async def block_user(
    user_id: int,
    service: Annotated[UsersService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Заблокировать пользователя (is_active=false). Доступно только moderator."""
    return await service.block_user(user_id, current_user)


@router.post("/{user_id}/unblock", response_model=UserResponse)
async def unblock_user(
    user_id: int,
    service: Annotated[UsersService, Depends(_get_service)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Разблокировать пользователя (is_active=true). Доступно только moderator."""
    return await service.unblock_user(user_id, current_user)
