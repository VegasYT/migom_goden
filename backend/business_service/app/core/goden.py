"""Обращения к API Goden.

От имени пользователя Мигома: API Goden принимает его access token (клиент migom-backend несёт
aud goden-api) с правами этого пользователя - владелец точки читает свой профиль, подключает
к точке заведение и читает меню точки. Права проверяет Goden.

От имени Мигома: сервисная учётная запись migom-integration читает меню точек, где подключено
заведение, и список пар "точка - заведение" (GET /migom/points).
"""

import time
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

    async def menu(self, point_id: uuid.UUID) -> list[dict]:
        """Меню точки Goden со всех страниц: [{dish: {id, name}, available, portions, ...}]."""
        items: list[dict] = []
        while True:
            page = (await self._request(
                "GET", f"/points/{point_id}/menu", params={"limit": _MENU_PAGE, "offset": len(items)}
            )).json()
            items.extend(page["items"])
            if not page["items"] or len(items) >= page["total"]:
                return items

    async def dishes(self, point_id: uuid.UUID) -> list[dict]:
        """Блюда, которые продаются на точке Goden: [{id, name}]."""
        return [item["dish"] for item in await self.menu(point_id)]

    async def migom_points(self) -> list[dict]:
        """Пары "точка - заведение" работающих точек: [{point_id, outlet_id}]. Только для migom-integration."""
        return (await self._request("GET", "/migom/points")).json()


# --- Сервисная учётная запись migom-integration ---

_PAIRS_TTL = 30
# пары нет в кеше: заведение могли только что подключить, список перечитывается чаще
_PAIRS_RECHECK = 5
_service_token: str | None = None
_service_token_expires_at = 0.0
_pairs: set[tuple[uuid.UUID, int]] = set()
_pairs_loaded_at = 0.0


async def _token(refresh: bool = False) -> str:
    global _service_token, _service_token_expires_at
    if not refresh and _service_token and time.monotonic() < _service_token_expires_at:
        return _service_token
    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT, transport=GodenClient.transport) as client:
            response = await client.post(
                f"{settings.keycloak_realm_url}/protocol/openid-connect/token",
                data={
                    "grant_type": "client_credentials",
                    "client_id": settings.goden_client_id,
                    "client_secret": settings.goden_client_secret,
                },
            )
    except httpx.HTTPError as e:
        raise GodenUnavailableError() from e
    if response.status_code != 200:
        # неверный секрет или клиента нет: для покупателя это та же недоступность Goden
        raise GodenUnavailableError()
    body = response.json()
    _service_token = body["access_token"]
    # с запасом, чтобы токен не истёк по дороге
    _service_token_expires_at = time.monotonic() + body.get("expires_in", 60) - 30
    return _service_token


async def as_migom(call):
    """Выполняет call(GodenClient) с токеном migom-integration; отозванный токен получает заново один раз."""
    try:
        return await call(GodenClient(await _token()))
    except GodenUnauthorizedError:
        return await call(GodenClient(await _token(refresh=True)))


async def confirmed(point_id: uuid.UUID, outlet_id: int) -> bool:
    """Подтверждает ли Goden, что к точке подключено именно это заведение. Список кешируется."""
    global _pairs, _pairs_loaded_at
    age = time.monotonic() - _pairs_loaded_at
    if age > _PAIRS_TTL or ((point_id, outlet_id) not in _pairs and age > _PAIRS_RECHECK):
        points = await as_migom(lambda goden: goden.migom_points())
        _pairs = {(uuid.UUID(p["point_id"]), p["outlet_id"]) for p in points}
        _pairs_loaded_at = time.monotonic()
    return (point_id, outlet_id) in _pairs
