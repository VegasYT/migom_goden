from typing import Annotated

import httpx
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.keycloak import KeycloakUnavailableError
from app.core.security import decode_token
from app.db.session import get_db
from app.modules.auth.exceptions import InvalidTokenError, UserInactiveError
from app.modules.auth.repository import UserRepository
from app.modules.users.models import User

bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer_scheme)],
    session: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    try:
        payload = await decode_token(credentials.credentials)
    except JWTError:
        raise InvalidTokenError()
    except httpx.HTTPError:
        raise KeycloakUnavailableError()

    # токен Keycloak называет пользователя его id в realm, роль и блокировка - в базе Мигома
    repo = UserRepository(session)
    user = await repo.get_by_keycloak_id(payload["sub"])

    if not user:
        raise InvalidTokenError()
    if not user.is_active:
        raise UserInactiveError()

    return user


def require_roles(*roles: str):
    """Dependency-фабрика для проверки роли. Пример: Depends(require_roles('moderator'))"""
    async def _check(current_user: Annotated[User, Depends(get_current_user)]) -> User:
        if current_user.role.name not in roles:
            from app.core.exceptions import ForbiddenError
            raise ForbiddenError()
        return current_user
    return _check
