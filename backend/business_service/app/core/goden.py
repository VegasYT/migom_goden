"""Обращения к API Goden от имени пользователя Мигома.

API Goden принимает access token Мигома (клиент migom-backend несёт aud goden-api) с правами
этого пользователя: владелец точки Goden читает свой профиль, подключает к точке заведение
и читает меню точки. Права проверяет Goden.
"""

import uuid

import httpx
from fastapi import HTTPException, status

from app.config import settings

_TIMEOUT = 10
# наибольшая страница меню в API Goden
_MENU_PAGE = 200


class GodenUnavailableError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Goden временно недоступен, попробуйте позже",
        )


class GodenUnauthorizedError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Goden не принял вход: выйдите и войдите в Мигом заново",
        )


class GodenForbiddenError(HTTPException):
    """Goden ответил 403 или 404: точка чужая, удалена или недоступна этому пользователю."""

    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Нет доступа к этой точке Goden: подключить можно только свою работающую точку",
        )


class GodenConflictError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail="Точка Goden отключена: подключить к ней заведение нельзя",
        )


class GodenClient:
    # подменяется в тестах (httpx.MockTransport)
    transport: httpx.AsyncBaseTransport | None = None

    def __init__(self, access_token: str) -> None:
        self._token = access_token

    async def _request(self, method: str, path: str, **kwargs) -> httpx.Response:
        try:
            async with httpx.AsyncClient(
                base_url=settings.goden_api_url,
                timeout=_TIMEOUT,
                transport=self.transport,
                headers={"Authorization": f"Bearer {self._token}"},
            ) as client:
                response = await client.request(method, path, **kwargs)
        except httpx.HTTPError as e:
            raise GodenUnavailableError() from e
        if response.status_code == 401:
            raise GodenUnauthorizedError()
        if response.status_code in (403, 404):
            raise GodenForbiddenError()
        if response.status_code == 409:
            raise GodenConflictError()
        if response.status_code != 200:
            # 5xx и неожиданные ответы: повторить можно позже, данные Мигома не меняются
            raise GodenUnavailableError()
        return response

    async def owned_points(self) -> list[dict]:
        """Работающие точки компаний Goden, которыми владеет пользователь."""
        profile = (await self._request("GET", "/me")).json()
        return [p for p in profile["points"] if p["owner"] and p["active"]]

    async def set_outlet(self, point_id: uuid.UUID, outlet_id: int | None) -> None:
        """Подключает к точке Goden заведение Мигома; None отключает."""
        await self._request("PUT", f"/points/{point_id}/migom", json={"outlet_id": outlet_id})

    async def dishes(self, point_id: uuid.UUID) -> list[dict]:
        """Блюда, которые продаются на точке Goden, со всех страниц меню: [{id, name}]."""
        dishes: list[dict] = []
        while True:
            page = (await self._request(
                "GET", f"/points/{point_id}/menu", params={"limit": _MENU_PAGE, "offset": len(dishes)}
            )).json()
            dishes.extend(item["dish"] for item in page["items"])
            if not page["items"] or len(dishes) >= page["total"]:
                return dishes
