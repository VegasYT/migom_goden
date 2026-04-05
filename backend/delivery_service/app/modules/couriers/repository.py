import logging
from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.couriers.models import Courier

logger = logging.getLogger(__name__)


class CourierRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, courier_id: int) -> Courier | None:
        result = await self._session.execute(
            select(Courier).where(Courier.id == courier_id)
        )
        return result.scalar_one_or_none()

    async def get_by_user_id(self, user_id: int) -> Courier | None:
        result = await self._session.execute(
            select(Courier).where(Courier.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_or_create(self, user_id: int) -> Courier:
        """Lazy init: создаёт профиль курьера при первом обращении."""
        courier = await self.get_by_user_id(user_id)
        if not courier:
            courier = Courier(user_id=user_id)
            self._session.add(courier)
            await self._session.flush()
            await self._session.refresh(courier)
        return courier

    async def list_all(self, offset: int = 0, limit: int = 20) -> tuple[list[Courier], int]:
        total = await self._session.scalar(select(func.count(Courier.id)))
        result = await self._session.execute(
            select(Courier).offset(offset).limit(limit)
        )
        return list(result.scalars().all()), total or 0

    async def update_location(
        self, courier: Courier, latitude: float, longitude: float
    ) -> Courier:
        courier.current_latitude = latitude
        courier.current_longitude = longitude
        courier.location_updated_at = datetime.now(timezone.utc)
        await self._session.flush()
        return courier

    async def set_blocked(self, courier: Courier, blocked: bool) -> Courier:
        courier.is_blocked = blocked
        await self._session.flush()
        return courier

    async def find_nearest_free_courier(
        self, latitude: float, longitude: float, exclude_courier_ids: list[int] | None = None
    ) -> "Courier | None":
        """Ближайший свободный курьер в активной смене без активного заказа.

        Сортировка по расстоянию от центра зоны курьера (zone_lat/lon) до адреса доставки.
        Если zone не задана - используется текущая позиция курьера.
        Исключает курьеров из exclude_courier_ids (уже отказавшихся).
        """
        from sqlalchemy import text
        from app.modules.shifts.models import Shift

        query = (
            select(Courier)
            .join(Shift, (Shift.courier_id == Courier.id) & Shift.is_active)
            .where(
                Courier.is_blocked.is_(False),
                # Курьер должен иметь либо zone, либо текущую позицию
                (Courier.zone_latitude.is_not(None) | Courier.current_latitude.is_not(None)),
            )
        )
        if exclude_courier_ids:
            query = query.where(Courier.id.not_in(exclude_courier_ids))

        # Расстояние считаем от центра зоны курьера (или текущей позиции как fallback)
        query = query.order_by(
            text(
                "ST_Distance("
                "  ST_MakePoint("
                "    COALESCE(couriers.zone_longitude, couriers.current_longitude)::float,"
                "    COALESCE(couriers.zone_latitude, couriers.current_latitude)::float"
                "  )::geography,"
                f"  ST_MakePoint({longitude}, {latitude})::geography"
                ")"
            )
        )

        # Добавляем фильтр: адрес доставки должен быть в радиусе курьера
        query = query.where(
            text(
                "ST_DWithin("
                "  ST_MakePoint("
                "    COALESCE(couriers.zone_longitude, couriers.current_longitude)::float,"
                "    COALESCE(couriers.zone_latitude, couriers.current_latitude)::float"
                "  )::geography,"
                f"  ST_MakePoint({longitude}, {latitude})::geography,"
                "  couriers.radius_km * 1000"
                ")"
            )
        )

        result = await self._session.execute(query)
        candidates = result.scalars().all()
        logger.info("find_nearest_free_courier: найдено кандидатов %s для lat=%s lon=%s", len(candidates), latitude, longitude)

        # Фильтруем тех у кого нет активного заказа (через таблицу orders)
        from app.modules.orders.models import Order, OrderStatus
        for courier in candidates:
            active_order = await self._session.scalar(
                select(Order.id).where(
                    Order.courier_id == courier.id,
                    Order.status.in_([OrderStatus.assigned, OrderStatus.in_delivery]),
                )
            )
            if not active_order:
                logger.info("find_nearest_free_courier: выбран курьер %s", courier.id)
                return courier
        logger.info("find_nearest_free_courier: все кандидаты заняты или список пуст")
        return None
