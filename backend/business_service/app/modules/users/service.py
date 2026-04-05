from app.core.storage import delete_photo, upload_photo
from app.core.security import hash_password, verify_password
from app.modules.users.exceptions import (
    SamePasswordError,
    UserAccessDeniedError,
    UserNotFoundError,
    WrongPasswordError,
)
from app.modules.users.models import User
from app.modules.users.repository import UsersRepository
from app.modules.users.schemas import (
    ChangePasswordRequest,
    UserListResponse,
    UserResponse,
    UserUpdateMe,
)


class UsersService:
    def __init__(self, repo: UsersRepository) -> None:
        self._repo = repo

    async def get_me(self, current_user: User) -> UserResponse:
        return UserResponse.model_validate(current_user)

    async def update_me(self, current_user: User, data: UserUpdateMe) -> UserResponse:
        updated = await self._repo.update(
            current_user,
            full_name=data.full_name,
            phone=data.phone,
        )
        return UserResponse.model_validate(updated)

    async def upload_avatar(
        self, current_user: User, data: bytes, content_type: str
    ) -> UserResponse:
        if current_user.avatar_url:
            await delete_photo(current_user.avatar_url)
        avatar_url = await upload_photo(data, content_type, prefix="avatars")
        updated = await self._repo.update(current_user, avatar_url=avatar_url)
        return UserResponse.model_validate(updated)

    async def change_password(
        self, current_user: User, data: ChangePasswordRequest
    ) -> None:
        if not verify_password(data.current_password, current_user.password_hash):
            raise WrongPasswordError()
        if data.current_password == data.new_password:
            raise SamePasswordError()
        await self._repo.update(current_user, password_hash=hash_password(data.new_password))

    async def get_user(self, user_id: int, current_user: User) -> UserResponse:
        self._require_moderator(current_user)
        user = await self._repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError()
        return UserResponse.model_validate(user)

    async def list_users(
        self, offset: int, limit: int, current_user: User
    ) -> UserListResponse:
        self._require_moderator(current_user)
        users, total = await self._repo.list_all(offset=offset, limit=limit)
        return UserListResponse(
            items=[UserResponse.model_validate(u) for u in users],
            total=total,
        )

    async def block_user(self, user_id: int, current_user: User) -> UserResponse:
        self._require_moderator(current_user)
        user = await self._repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError()
        if user.id == current_user.id:
            raise UserAccessDeniedError()
        updated = await self._repo.set_active(user, is_active=False)
        return UserResponse.model_validate(updated)

    async def unblock_user(self, user_id: int, current_user: User) -> UserResponse:
        self._require_moderator(current_user)
        user = await self._repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError()
        updated = await self._repo.set_active(user, is_active=True)
        return UserResponse.model_validate(updated)

    def _require_moderator(self, user: User) -> None:
        if user.role.name != "moderator":
            raise UserAccessDeniedError()
