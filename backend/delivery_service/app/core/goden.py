"""Заказы на кухню точки Goden от имени Мигома.

Сервисная учётная запись migom-integration (client_credentials) оформляет и отменяет заказы
на точках, где владелец подключил заведение Мигома. Пару "точка - заведение" Мигом сверяет
с GET /migom/points: подключение в Goden может измениться в любой момент.
"""

import time
import uuid

import httpx
from fastapi import HTTPException, status

from app.config import settings

_TIMEOUT = 10
_PAIRS_TTL = 30
# пары нет в кеше: заведение могли только что подключить, список перечитывается чаще
_PAIRS_RECHECK = 5


class GodenUnavailableError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Склад заведения временно недоступен, попробуйте позже",
        )


class GodenRefusedError(Exception):
    """Goden отказал в операции (4xx): точка не подключена, заказ уже отменён и т.п."""

    def __init__(self, status_code: int) -> None:
        super().__init__(f"Goden ответил {status_code}")
        self.status_code = status_code


class _Unauthorized(Exception):
    pass


_token: str | None = None
_token_expires_at = 0.0
_pairs: set[tuple[uuid.UUID, int]] = set()
_pairs_loaded_at = 0.0
# подменяется в тестах (httpx.MockTransport)
transport: httpx.AsyncBaseTransport | None = None


async def _service_token(refresh: bool = False) -> str:
    global _token, _token_expires_at
    if not refresh and _token and time.monotonic() < _token_expires_at:
        return _token
    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT, transport=transport) as client:
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
        raise GodenUnavailableError()
    body = response.json()
    _token = body["access_token"]
    # с запасом, чтобы токен не истёк по дороге
    _token_expires_at = time.monotonic() + body.get("expires_in", 60) - 30
    return _token


async def _send(token: str, method: str, path: str, **kwargs) -> httpx.Response:
    try:
        async with httpx.AsyncClient(
            base_url=settings.goden_api_url, timeout=_TIMEOUT, transport=transport,
            headers={"Authorization": f"Bearer {token}"},
        ) as client:
            response = await client.request(method, path, **kwargs)
    except httpx.HTTPError as e:
        raise GodenUnavailableError() from e
    if response.status_code == 401:
        raise _Unauthorized()
    if response.status_code >= 500:
        raise GodenUnavailableError()
    if response.status_code >= 400:
        raise GodenRefusedError(response.status_code)
    return response


async def _request(method: str, path: str, **kwargs) -> httpx.Response:
    """Запрос от имени migom-integration; отозванный токен получает заново один раз."""
    try:
        return await _send(await _service_token(), method, path, **kwargs)
    except _Unauthorized:
        try:
            return await _send(await _service_token(refresh=True), method, path, **kwargs)
        except _Unauthorized:
            raise GodenUnavailableError()


async def confirmed(point_id: uuid.UUID, outlet_id: int) -> bool:
    """Подтверждает ли Goden, что к точке подключено именно это заведение. Список кешируется."""
    global _pairs, _pairs_loaded_at
    age = time.monotonic() - _pairs_loaded_at
    if age > _PAIRS_TTL or ((point_id, outlet_id) not in _pairs and age > _PAIRS_RECHECK):
        points = (await _request("GET", "/migom/points")).json()
        _pairs = {(uuid.UUID(p["point_id"]), p["outlet_id"]) for p in points}
        _pairs_loaded_at = time.monotonic()
    return (point_id, outlet_id) in _pairs


async def place_order(point_id: uuid.UUID, portions: dict[uuid.UUID, int]) -> dict:
    """Оформляет заказ на кухню точки. Ответ Goden - и для принятого, и для отклонённого
    из-за нехватки продуктов (поле status). Ключ идемпотентности защищает повтор при сбое сети."""
    key = str(uuid.uuid4())
    body = {"items": [{"dish_id": str(dish), "portions": n} for dish, n in portions.items()]}
    try:
        response = await _request("POST", f"/points/{point_id}/orders", json=body, headers={"Idempotency-Key": key})
    except GodenUnavailableError:
        # ответ мог потеряться по дороге: повтор с тем же ключом не спишет продукты дважды
        response = await _request("POST", f"/points/{point_id}/orders", json=body, headers={"Idempotency-Key": key})
    return response.json()


async def cancel_order(point_id: uuid.UUID, order_id: uuid.UUID) -> None:
    """Отменяет заказ в Goden: продукты возвращаются в партии."""
    await _request("POST", f"/points/{point_id}/orders/{order_id}/cancel", headers={"Idempotency-Key": str(order_id)})
