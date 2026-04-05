from datetime import datetime, timezone

from app.core.cache import cache_delete, cache_get, cache_set
from app.modules.discounts.exceptions import (
    DiscountNotFoundError,
    PromoCodeExpiredError,
    PromoCodeNotFoundError,
)
from app.modules.discounts.repository import DiscountRepository, PromoCodeRepository
from app.modules.discounts.schemas import (
    DiscountCreate,
    DiscountListResponse,
    DiscountResponse,
    DiscountUpdate,
    PromoCodeCreate,
    PromoCodeResponse,
)
from app.modules.users.models import User

_DISCOUNTS_CACHE_KEY = "discounts:active"
_CACHE_TTL = 300  # 5 минут


class DiscountService:
    def __init__(self, repo: DiscountRepository) -> None:
        self._repo = repo

    async def create(self, data: DiscountCreate, current_user: User) -> DiscountResponse:
        discount = await self._repo.create(**data.model_dump())
        await cache_delete(_DISCOUNTS_CACHE_KEY)
        return DiscountResponse.model_validate(discount)

    async def get_by_id(self, discount_id: int) -> DiscountResponse:
        discount = await self._repo.get_by_id(discount_id)
        if not discount:
            raise DiscountNotFoundError()
        return DiscountResponse.model_validate(discount)

    async def list_active(self, offset: int, limit: int) -> DiscountListResponse:
        cached = await cache_get(_DISCOUNTS_CACHE_KEY)
        if cached:
            return DiscountListResponse(**cached)

        discounts, total = await self._repo.list_active(offset=offset, limit=limit)
        response = DiscountListResponse(
            items=[DiscountResponse.model_validate(d) for d in discounts],
            total=total,
        )
        await cache_set(_DISCOUNTS_CACHE_KEY, response.model_dump(mode="json"), ttl=_CACHE_TTL)
        return response

    async def update(
        self, discount_id: int, data: DiscountUpdate, current_user: User
    ) -> DiscountResponse:
        discount = await self._repo.get_by_id(discount_id)
        if not discount:
            raise DiscountNotFoundError()

        updated = await self._repo.update(discount, **data.model_dump(exclude_unset=True))
        await cache_delete(_DISCOUNTS_CACHE_KEY)
        return DiscountResponse.model_validate(updated)

    async def delete(self, discount_id: int, current_user: User) -> None:
        discount = await self._repo.get_by_id(discount_id)
        if not discount:
            raise DiscountNotFoundError()

        await self._repo.delete(discount)
        await cache_delete(_DISCOUNTS_CACHE_KEY)


class PromoCodeService:
    def __init__(self, repo: PromoCodeRepository) -> None:
        self._repo = repo

    async def create(self, data: PromoCodeCreate, current_user: User) -> PromoCodeResponse:
        promo = await self._repo.create(**data.model_dump())
        return PromoCodeResponse.model_validate(promo)

    async def get_by_code(self, code: str) -> PromoCodeResponse:
        promo = await self._repo.get_by_code(code)
        if not promo:
            raise PromoCodeNotFoundError()

        now = datetime.now(timezone.utc)
        # Проверяем активность, срок действия и остаток использований
        if not promo.is_active or promo.expires_at < now or (
            promo.uses_left is not None and promo.uses_left <= 0
        ):
            raise PromoCodeExpiredError()

        return PromoCodeResponse.model_validate(promo)

    async def delete(self, promo_id: int, current_user: User) -> None:
        promo = await self._repo.get_by_id(promo_id)
        if not promo:
            raise PromoCodeNotFoundError()

        await self._repo.delete(promo)
