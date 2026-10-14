import uuid

from sqlalchemy.exc import IntegrityError

from app.core.goden import GodenClient, GodenConflictError, GodenForbiddenError
from app.modules.catalog.exceptions import GodenDishLinkedError
from app.modules.catalog.models import CatalogItem
from app.modules.catalog.repository import CatalogRepository
from app.modules.companies.repository import CompanyRepository
from app.modules.goden.exceptions import GodenPointTakenError, OutletNotBoundError
from app.modules.goden.schemas import GodenDishResponse, GodenPointResponse, LinkedItem
from app.modules.outlets.exceptions import OutletAccessDeniedError, OutletNotFoundError
from app.modules.outlets.models import Outlet
from app.modules.outlets.repository import OutletRepository
from app.modules.outlets.schemas import OutletResponse
from app.modules.users.models import User


def _same_name(a: str, b: str) -> bool:
    return a.strip().casefold() == b.strip().casefold()


class GodenBindingService:
    """Связь заведений с точками Goden и товаров с блюдами Goden. Запросы в Goden идут
    с токеном пользователя: свою ли точку он подключает, проверяет Goden."""

    def __init__(
        self,
        goden: GodenClient,
        outlets: OutletRepository,
        companies: CompanyRepository,
        catalog: CatalogRepository,
    ) -> None:
        self._goden = goden
        self._outlets = outlets
        self._companies = companies
        self._catalog = catalog

    async def owned_points(self) -> list[GodenPointResponse]:
        points = await self._goden.owned_points()
        bound = await self._outlets.list_by_goden_points([uuid.UUID(p["id"]) for p in points])
        outlet_of = {o.goden_point_id: o.id for o in bound}
        return [
            GodenPointResponse(
                id=p["id"], name=p["name"], company_name=p["company_name"],
                outlet_id=outlet_of.get(uuid.UUID(p["id"])),
            )
            for p in points
        ]

    async def set_point(self, outlet_id: int, point_id: uuid.UUID | None, user: User) -> OutletResponse:
        outlet = await self._outlet(outlet_id, user)
        old = outlet.goden_point_id
        if point_id is not None:
            taken = await self._outlets.list_by_goden_points([point_id])
            if any(o.id != outlet.id for o in taken):
                raise GodenPointTakenError()
            # сначала Goden: база Мигома меняется, только если Goden подключил заведение
            await self._goden.set_outlet(point_id, outlet.id)
        if old is not None and old != point_id:
            await self._release(old)
        outlet.goden_point_id = point_id
        try:
            await self._outlets.flush()
        except IntegrityError:
            # точку только что занял другой запрос
            raise GodenPointTakenError()
        return OutletResponse.model_validate(outlet)

    async def dishes(self, outlet_id: int, user: User) -> list[GodenDishResponse]:
        outlet = await self._outlet(outlet_id, user)
        dishes = await self._goden_dishes(outlet)
        items = await self._catalog.list_items(outlet.company_id)
        return self._with_items(dishes, items)

    async def link_by_name(self, outlet_id: int, user: User) -> list[GodenDishResponse]:
        """Связывает блюда без товара с единственным несвязанным товаром того же названия."""
        outlet = await self._outlet(outlet_id, user)
        dishes = await self._goden_dishes(outlet)
        items = await self._catalog.list_items(outlet.company_id)
        linked = {i.goden_dish_id for i in items if i.goden_dish_id}
        free = [i for i in items if i.goden_dish_id is None]
        for dish in dishes:
            dish_id = uuid.UUID(dish["id"])
            if dish_id in linked:
                continue
            same = [i for i in free if _same_name(i.name, dish["name"])]
            # у двух блюд с одним названием пара неоднозначна, и у второго товар уже занят
            if len(same) == 1 and sum(_same_name(d["name"], dish["name"]) for d in dishes) == 1:
                same[0].goden_dish_id = dish_id
                free.remove(same[0])
        try:
            await self._catalog.flush()
        except IntegrityError:
            raise GodenDishLinkedError()
        return self._with_items(dishes, items)

    async def _release(self, point_id: uuid.UUID) -> None:
        """Отключает заведение в Goden. Отказ по правам не мешает снять связь в Мигоме:
        к этой точке Мигом больше не обращается. Недоступность Goden - ошибка."""
        try:
            await self._goden.set_outlet(point_id, None)
        except (GodenForbiddenError, GodenConflictError):
            pass

    async def _goden_dishes(self, outlet: Outlet) -> list[dict]:
        if outlet.goden_point_id is None:
            raise OutletNotBoundError()
        return await self._goden.dishes(outlet.goden_point_id)

    @staticmethod
    def _with_items(dishes: list[dict], items: list[CatalogItem]) -> list[GodenDishResponse]:
        item_of = {i.goden_dish_id: i for i in items if i.goden_dish_id}
        result = []
        for dish in dishes:
            item = item_of.get(uuid.UUID(dish["id"]))
            result.append(GodenDishResponse(
                id=dish["id"], name=dish["name"],
                item=LinkedItem(id=item.id, name=item.name) if item else None,
            ))
        return result

    async def _outlet(self, outlet_id: int, user: User) -> Outlet:
        """Заведение, которым распоряжается пользователь: владелец компании или модератор."""
        outlet = await self._outlets.get_by_id(outlet_id)
        if not outlet:
            raise OutletNotFoundError()
        if user.role.name != "moderator":
            company = await self._companies.get_by_id(outlet.company_id)
            if not company or company.owner_id != user.id:
                raise OutletAccessDeniedError()
        return outlet
