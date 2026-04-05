from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.outlets.models import OutletManager
from app.modules.users.models import Role, User


class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_email(self, email: str) -> User | None:
        result = await self._session.execute(
            select(User).options(selectinload(User.role)).where(User.email == email)
        )
        return result.scalar_one_or_none()

    async def get_by_id(self, user_id: int) -> User | None:
        result = await self._session.execute(
            select(User).options(selectinload(User.role)).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_role_by_id(self, role_id: int) -> Role | None:
        result = await self._session.execute(select(Role).where(Role.id == role_id))
        return result.scalar_one_or_none()

    async def get_outlet_id_for_manager(self, user_id: int) -> int | None:
        """Возвращает outlet_id менеджера (первая запись если назначен на несколько)."""
        result = await self._session.execute(
            select(OutletManager.outlet_id).where(OutletManager.user_id == user_id).limit(1)
        )
        return result.scalar_one_or_none()

    async def list_roles(self) -> list[Role]:
        result = await self._session.execute(select(Role))
        return list(result.scalars().all())

    async def create(
        self,
        email: str,
        password_hash: str,
        full_name: str,
        role_id: int,
        phone: str | None = None,
    ) -> User:
        user = User(
            email=email,
            password_hash=password_hash,
            full_name=full_name,
            role_id=role_id,
            phone=phone,
        )
        self._session.add(user)
        await self._session.flush()
        # Перечитываем с подгрузкой role, т.к. flush не заполняет relationship
        return await self.get_by_id(user.id)
