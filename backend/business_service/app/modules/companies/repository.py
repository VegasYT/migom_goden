from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.companies.models import Company


class CompanyRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, company_id: int) -> Company | None:
        result = await self._session.execute(
            select(Company).where(Company.id == company_id)
        )
        return result.scalar_one_or_none()

    async def get_by_owner(self, owner_id: int) -> list[Company]:
        result = await self._session.execute(
            select(Company).where(Company.owner_id == owner_id)
        )
        return list(result.scalars().all())

    async def list_all(
        self, offset: int = 0, limit: int = 20, search: str | None = None
    ) -> tuple[list[Company], int]:
        query = select(Company)
        if search:
            query = query.where(Company.name.ilike(f"%{search}%"))

        total = await self._session.scalar(select(func.count()).select_from(query.subquery()))
        result = await self._session.execute(query.offset(offset).limit(limit))
        return list(result.scalars().all()), total or 0

    async def create(self, owner_id: int, name: str, description: str | None) -> Company:
        company = Company(owner_id=owner_id, name=name, description=description)
        self._session.add(company)
        await self._session.flush()
        await self._session.refresh(company)
        return company

    async def update(self, company: Company, **fields) -> Company:
        for key, value in fields.items():
            if value is not None:
                setattr(company, key, value)
        await self._session.flush()
        await self._session.refresh(company)
        return company

    async def delete(self, company: Company) -> None:
        await self._session.delete(company)
        await self._session.flush()
