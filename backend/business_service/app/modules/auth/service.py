from jose import JWTError
from sqlalchemy.exc import IntegrityError

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.modules.auth.exceptions import (
    InvalidCredentialsError,
    InvalidTokenError,
    PhoneAlreadyExistsError,
    RoleNotAssignableError,
    UserAlreadyExistsError,
    UserInactiveError,
)
from app.modules.auth.repository import UserRepository
from app.modules.auth.schemas import LoginRequest, RegisterRequest, TokenResponse
from app.modules.users.models import User


class AuthService:
    def __init__(self, repo: UserRepository) -> None:
        self._repo = repo

    async def register(self, data: RegisterRequest) -> TokenResponse:
        existing = await self._repo.get_by_email(data.email)
        if existing:
            raise UserAlreadyExistsError()

        role = await self._repo.get_role_by_id(data.role_id)
        if not role or not role.is_assignable:
            raise RoleNotAssignableError()

        try:
            user = await self._repo.create(
                email=data.email,
                password_hash=hash_password(data.password),
                full_name=data.full_name,
                role_id=data.role_id,
                phone=data.phone,
            )
        except IntegrityError as e:
            if "users_phone_key" in str(e.orig):
                raise PhoneAlreadyExistsError()
            raise
        return await self._issue_tokens(user)

    async def login(self, data: LoginRequest) -> TokenResponse:
        user = await self._repo.get_by_email(data.email)
        if not user or not verify_password(data.password, user.password_hash):
            raise InvalidCredentialsError()
        if not user.is_active:
            raise UserInactiveError()
        return await self._issue_tokens(user)

    async def refresh(self, refresh_token: str) -> TokenResponse:
        try:
            payload = decode_token(refresh_token)
        except JWTError:
            raise InvalidTokenError()

        if payload.get("type") != "refresh":
            raise InvalidTokenError()

        user_id = int(payload["sub"])
        user = await self._repo.get_by_id(user_id)
        if not user or not user.is_active:
            raise InvalidTokenError()

        return await self._issue_tokens(user)

    async def list_roles(self) -> list:
        return await self._repo.list_roles()

    async def logout(self, user_id: int) -> None:
        # Stateless - токен не хранится, logout только на клиенте
        pass

    async def _issue_tokens(self, user: User) -> TokenResponse:
        role_name = user.role.name if user.role else "customer"
        outlet_id = None
        if role_name == "outlet_manager":
            outlet_id = await self._repo.get_outlet_id_for_manager(user.id)
        access = create_access_token(user.id, role_name, outlet_id=outlet_id)
        refresh = create_refresh_token(user.id, role_name, outlet_id=outlet_id)
        return TokenResponse(access_token=access, refresh_token=refresh)
