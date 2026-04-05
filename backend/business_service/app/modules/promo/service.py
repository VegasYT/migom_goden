from app.core.cache import cache_delete, cache_get, cache_set
from app.modules.promo.exceptions import PromoBannerNotFoundError
from app.modules.promo.repository import PromoBannerRepository
from app.modules.promo.schemas import (
    PromoBannerCreate,
    PromoBannerListResponse,
    PromoBannerResponse,
    PromoBannerUpdate,
)
from app.modules.users.models import User

_BANNERS_CACHE_KEY = "promo_banners:active"
_CACHE_TTL = 300  # 5 минут


class PromoBannerService:
    def __init__(self, repo: PromoBannerRepository) -> None:
        self._repo = repo

    async def list_active(self) -> PromoBannerListResponse:
        cached = await cache_get(_BANNERS_CACHE_KEY)
        if cached:
            return PromoBannerListResponse(**cached)

        banners, total = await self._repo.list_active()
        response = PromoBannerListResponse(
            items=[PromoBannerResponse.model_validate(b) for b in banners],
            total=total,
        )
        await cache_set(_BANNERS_CACHE_KEY, response.model_dump(mode="json"), ttl=_CACHE_TTL)
        return response

    async def create(self, data: PromoBannerCreate, current_user: User) -> PromoBannerResponse:
        banner = await self._repo.create(**data.model_dump())
        await cache_delete(_BANNERS_CACHE_KEY)
        return PromoBannerResponse.model_validate(banner)

    async def update(
        self, banner_id: int, data: PromoBannerUpdate, current_user: User
    ) -> PromoBannerResponse:
        banner = await self._repo.get_by_id(banner_id)
        if not banner:
            raise PromoBannerNotFoundError()

        updated = await self._repo.update(banner, **data.model_dump(exclude_unset=True))
        await cache_delete(_BANNERS_CACHE_KEY)
        return PromoBannerResponse.model_validate(updated)

    async def delete(self, banner_id: int, current_user: User) -> None:
        banner = await self._repo.get_by_id(banner_id)
        if not banner:
            raise PromoBannerNotFoundError()

        await self._repo.delete(banner)
        await cache_delete(_BANNERS_CACHE_KEY)
