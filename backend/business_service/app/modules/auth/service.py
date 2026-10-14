from sqlalchemy.exc import IntegrityError

from app.core import keycloak
from app.core.security import verify_password
from app.modules.auth.exceptions import (
    InvalidCredentialsError,
    InvalidTokenError,
    PhoneAlreadyExistsError,
    RoleNotAssignableError,
    UserAlreadyExistsError,
    UserInactiveError,
)
from app.modules.auth.repository import UserRepository
from app.modules.auth.schemas import IdentityResponse, LoginRequest, RegisterRequest, TokenResponse
from app.modules.users.models import User


def _token_response(tokens: dict) -> TokenResponse:
    return TokenResponse(access_token=tokens["access_token"], refresh_token=tokens["refresh_token"])


class AuthService:
    """Вход и регистрация через Keycloak (realm goden); пользователь, роль и блокировка - в базе Мигома."""

    def __init__(self, repo: UserRepository) -> None:
        self._repo = repo

    async def register(self, data: RegisterRequest) -> TokenResponse:
        if await self._repo.get_by_email(data.email):
            raise UserAlreadyExistsError()

        role = await self._repo.get_role_by_id(data.role_id)
        if not role or not role.is_assignable:
            raise RoleNotAssignableError()

        # почта уже есть в realm (например, у пользователя Goden): привязываем её, если пароль от неё верный
        created = False
        keycloak_id = await keycloak.find_user_id(data.email)
        if keycloak_id:
            try:
                await keycloak.password_grant(data.email, data.password)
            except keycloak.KeycloakRejectedError:
                raise UserAlreadyExistsError()
        else:
            try:
                keycloak_id = await keycloak.create_user(data.email, data.password, data.full_name)
            except keycloak.KeycloakUserExistsError:
                raise UserAlreadyExistsError()
            created = True

        try:
            await self._repo.create(
                email=data.email,
                keycloak_id=keycloak_id,
                full_name=data.full_name,
                role_id=data.role_id,
                phone=data.phone,
            )
        except IntegrityError as e:
            # учётная запись Keycloak без пользователя Мигома заняла бы почту навсегда
            if created:
                await keycloak.delete_user(keycloak_id)
            if "users_phone_key" in str(e.orig):
                raise PhoneAlreadyExistsError()
            raise
        return _token_response(await keycloak.password_grant(data.email, data.password))

    async def login(self, data: LoginRequest) -> TokenResponse:
        user = await self._repo.get_by_email(data.email)
        if not user:
            raise InvalidCredentialsError()
        try:
            tokens = await keycloak.password_grant(data.email, data.password)
        except keycloak.KeycloakRejectedError:
            tokens = await self._migrate(user, data.password)

        if not user.is_active:
            raise UserInactiveError()
        if user.keycloak_id is None:
            await self._repo.link_keycloak(user, keycloak.subject_of(tokens["access_token"]))
        return _token_response(tokens)

    async def _migrate(self, user: User, password: str) -> dict:
        """Перенос в Keycloak при первом входе: пароль сверяется с прежним хешем bcrypt."""
        if user.keycloak_id or not user.password_hash or not verify_password(password, user.password_hash):
            raise InvalidCredentialsError()
        # почту в realm заняла другая учётная запись (например, Goden): войти можно только её паролем
        if await keycloak.find_user_id(user.email):
            raise InvalidCredentialsError()
        keycloak_id = await keycloak.create_user(user.email, password, user.full_name)
        await self._repo.link_keycloak(user, keycloak_id)
        return await keycloak.password_grant(user.email, password)

    async def refresh(self, refresh_token: str) -> TokenResponse:
        try:
            tokens = await keycloak.refresh_grant(refresh_token)
        except keycloak.KeycloakRejectedError:
            raise InvalidTokenError()

        user = await self._repo.get_by_keycloak_id(keycloak.subject_of(tokens["access_token"]))
        if not user or not user.is_active:
            raise InvalidTokenError()
        return _token_response(tokens)

    async def list_roles(self) -> list:
        return await self._repo.list_roles()

    async def logout(self, refresh_token: str | None) -> None:
        # клиенты Мигома refresh-токен при выходе не присылают: тогда он доживает свой срок
        if refresh_token:
            await keycloak.logout(refresh_token)

    async def identity(self, user: User) -> IdentityResponse:
        role = user.role.name
        outlet_id = await self._repo.get_outlet_id_for_manager(user.id) if role == "outlet_manager" else None
        return IdentityResponse(user_id=user.id, role=role, outlet_id=outlet_id)
