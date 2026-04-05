from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.users.models import User


class UsersRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, user_id: int) -> User | None:
        result = await self._session.execute(
            select(User).options(selectinload(User.role)).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def list_all(self, offset: int = 0, limit: int = 20) -> tuple[list[User], int]:
        total = await self._session.scalar(select(func.count(User.id)))
        result = await self._session.execute(
            select(User)
            .options(selectinload(User.role))
            .offset(offset)
            .limit(limit)
            .order_by(User.created_at.desc())
        )
        return list(result.scalars().all()), total

    async def update(self, user: User, **fields) -> User:
        for key, value in fields.items():
            if value is not None:
                setattr(user, key, value)
        await self._session.flush()
        await self._session.refresh(user)
        return user

    async def set_active(self, user: User, is_active: bool) -> User:
        user.is_active = is_active
        await self._session.flush()
        await self._session.refresh(user)
        return user
