from dataclasses import dataclass
from typing import Annotated

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ForbiddenError, UnauthorizedError
from app.core.security import decode_token
from app.db.session import get_db

bearer_scheme = HTTPBearer()


@dataclass
class TokenData:
    """Пользователь Мигома по токену Keycloak: id, роль и точка управляющего из общей базы."""
    user_id: int
    role: str
    outlet_id: int | None = None


# пользователи, роли и назначения управляющих - таблицы business_service в той же базе
_USER_BY_KEYCLOAK_ID = text("""
    SELECT u.id, r.name AS role, u.is_active,
           (SELECT om.outlet_id FROM outlet_managers om
            WHERE om.user_id = u.id ORDER BY om.id LIMIT 1) AS outlet_id
    FROM users u JOIN roles r ON r.id = u.role_id
    WHERE u.keycloak_id = :keycloak_id
""")


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer_scheme)],
    session: Annotated[AsyncSession, Depends(get_db)],
) -> TokenData:
    try:
        payload = await decode_token(credentials.credentials)
    except JWTError:
        raise UnauthorizedError("Невалидный или истёкший токен")
    except httpx.HTTPError:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Сервис входа временно недоступен")

    user = (await session.execute(_USER_BY_KEYCLOAK_ID, {"keycloak_id": payload["sub"]})).one_or_none()
    if user is None:
        raise UnauthorizedError("Пользователь не зарегистрирован в Мигоме")
    if not user.is_active:
        raise ForbiddenError("Аккаунт заблокирован")

    return TokenData(
        user_id=user.id,
        role=user.role,
        outlet_id=user.outlet_id if user.role == "outlet_manager" else None,
    )


def require_roles(*roles: str):
    """Dependency-фабрика для проверки роли. Пример: Depends(require_roles('courier'))"""
    async def _check(current_user: Annotated[TokenData, Depends(get_current_user)]) -> TokenData:
        if current_user.role not in roles:
            raise ForbiddenError()
        return current_user
    return _check
