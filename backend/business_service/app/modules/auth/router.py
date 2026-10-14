from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.modules.auth.repository import UserRepository
from app.modules.auth.schemas import (
    IdentityResponse,
    LoginRequest,
    LogoutRequest,
    RefreshRequest,
    RegisterRequest,
    RoleResponse,
    TokenResponse,
)
from app.modules.auth.service import AuthService
from app.modules.users.models import User

router = APIRouter(prefix="/auth", tags=["Аутентификация"])


def _get_service(session: Annotated[AsyncSession, Depends(get_db)]) -> AuthService:
    return AuthService(UserRepository(session))


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(
    data: RegisterRequest,
    service: Annotated[AuthService, Depends(_get_service)],
):
    """Регистрация нового пользователя. Возвращает access и refresh токены."""
    return await service.register(data)


@router.post("/login", response_model=TokenResponse)
async def login(
    data: LoginRequest,
    service: Annotated[AuthService, Depends(_get_service)],
):
    """Вход по email и паролю. Возвращает access и refresh токены."""
    return await service.login(data)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    data: RefreshRequest,
    service: Annotated[AuthService, Depends(_get_service)],
):
    """Обновление access токена по refresh токену."""
    return await service.refresh(data.refresh_token)


@router.get("/roles", response_model=list[RoleResponse])
async def list_roles(
    service: Annotated[AuthService, Depends(_get_service)],
):
    """Список всех ролей. Используется при регистрации для выбора роли."""
    return await service.list_roles()


@router.post("/logout", status_code=204)
async def logout(
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[AuthService, Depends(_get_service)],
    data: LogoutRequest | None = None,
):
    """Выход из системы. Переданный refresh-токен отзывается в Keycloak."""
    await service.logout(data.refresh_token if data else None)


@router.get("/identity", response_model=IdentityResponse)
async def identity(
    current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[AuthService, Depends(_get_service)],
):
    """Id пользователя в Мигоме, роль и точка управляющего по токену Keycloak."""
    return await service.identity(current_user)
