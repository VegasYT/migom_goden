"""Клиент API Goden без сети: ответы Goden подменяет httpx.MockTransport."""
import asyncio
import json
import os
import uuid

# настройки читаются при импорте app.config; тесту база и MinIO не нужны
os.environ.update({
    "DB_HOST": "-", "DB_NAME": "-", "DB_USER": "-", "DB_PASSWORD": "-",
    "MINIO_ENDPOINT": "-", "MINIO_ACCESS_KEY": "-", "MINIO_SECRET_KEY": "-",
    "KEYCLOAK_REALM_URL": "http://keycloak/realms/goden",
    "KEYCLOAK_ISSUER": "http://localhost:8180/realms/goden",
    "KEYCLOAK_CLIENT_SECRET": "-",
    "GODEN_API_URL": "http://goden/api/v1",
})

import httpx  # noqa: E402
import pytest  # noqa: E402

from app.core import goden  # noqa: E402

POINT = uuid.UUID("0198c0de-0000-7000-8000-000000000012")


def _client(handler) -> goden.GodenClient:
    client = goden.GodenClient("user-token")
    client.transport = httpx.MockTransport(handler)
    return client


def test_owned_points_keeps_own_working_points():
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path == "/api/v1/me"
        assert request.headers["Authorization"] == "Bearer user-token"
        return httpx.Response(200, json={"points": [
            {"id": "a", "name": "Своя", "owner": True, "active": True},
            {"id": "b", "name": "Отключённая", "owner": True, "active": False},
            {"id": "c", "name": "Где назначен", "owner": False, "active": True},
        ]})

    points = asyncio.run(_client(handler).owned_points())
    assert [p["id"] for p in points] == ["a"]


def test_set_outlet_sends_outlet_or_null():
    bodies = []

    def handler(request: httpx.Request) -> httpx.Response:
        assert request.method == "PUT"
        assert request.url.path == f"/api/v1/points/{POINT}/migom"
        bodies.append(json.loads(request.content))
        return httpx.Response(200, json=bodies[-1])

    client = _client(handler)
    asyncio.run(client.set_outlet(POINT, 7))
    asyncio.run(client.set_outlet(POINT, None))
    assert bodies == [{"outlet_id": 7}, {"outlet_id": None}]


def test_dishes_reads_every_page():
    total = 250

    def handler(request: httpx.Request) -> httpx.Response:
        offset, limit = int(request.url.params["offset"]), int(request.url.params["limit"])
        items = [{"dish": {"id": str(i), "name": f"Блюдо {i}"}} for i in range(offset, min(offset + limit, total))]
        return httpx.Response(200, json={"items": items, "total": total})

    dishes = asyncio.run(_client(handler).dishes(POINT))
    assert len(dishes) == total
    assert dishes[-1] == {"id": "249", "name": "Блюдо 249"}


@pytest.mark.parametrize(("status", "error"), [
    (401, goden.GodenUnauthorizedError),
    (403, goden.GodenForbiddenError),
    (404, goden.GodenForbiddenError),
    (409, goden.GodenConflictError),
    (500, goden.GodenUnavailableError),
])
def test_errors(status, error):
    client = _client(lambda request: httpx.Response(status, json={"type": "x", "title": "x", "status": status}))
    with pytest.raises(error):
        asyncio.run(client.set_outlet(POINT, 7))


def test_network_failure_is_unavailable():
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("refused")

    with pytest.raises(goden.GodenUnavailableError):
        asyncio.run(_client(handler).owned_points())
