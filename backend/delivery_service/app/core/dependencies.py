from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError

from app.core.exceptions import ForbiddenError, UnauthorizedError
from app.core.security import decode_token

bearer_scheme = HTTPBearer()


@dataclass
class TokenData:
    """Данные из JWT-токена. Сервис доверяет токену - в БД за пользователем не ходим."""
    user_id: int
    role: str
    outlet_id: int | None = None


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer_scheme)],
) -> TokenData:
    try:
        payload = decode_token(credentials.credentials)
    except JWTError:
        raise UnauthorizedError("Невалидный или истёкший токен")

    if payload.get("type") != "access":
        raise UnauthorizedError("Ожидается access-токен")

    return TokenData(
        user_id=int(payload["sub"]),
        role=payload["role"],
        outlet_id=payload.get("outlet_id"),
    )


def require_roles(*roles: str):
    """Dependency-фабрика для проверки роли. Пример: Depends(require_roles('courier'))"""
    async def _check(current_user: Annotated[TokenData, Depends(get_current_user)]) -> TokenData:
        if current_user.role not in roles:
            raise ForbiddenError()
        return current_user
    return _check
