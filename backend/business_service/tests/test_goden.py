"""Клиент API Goden без сети: ответы Goden подменяет httpx.MockTransport."""
import asyncio
import json
import uuid

import httpx
import pytest

from app.core import goden

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


@pytest.fixture
def migom(monkeypatch):
    """Сервисная учётная запись: Keycloak выдаёт токены по порядку, Goden отвечает по handler."""
    monkeypatch.setattr(goden, "_service_token", None)
    monkeypatch.setattr(goden, "_pairs_loaded_at", 0.0)
    calls = {"tokens": 0, "points": 0}

    def install(goden_handler):
        def handler(request: httpx.Request) -> httpx.Response:
            if request.url.path.endswith("/protocol/openid-connect/token"):
                form = dict(httpx.QueryParams(request.content.decode()))
                assert form["grant_type"] == "client_credentials"
                assert form["client_id"] == "migom-integration"
                assert form["client_secret"] == "integration-secret"
                calls["tokens"] += 1
                return httpx.Response(200, json={"access_token": f"token-{calls['tokens']}", "expires_in": 300})
            if request.url.path == "/api/v1/migom/points":
                calls["points"] += 1
            return goden_handler(request)

        monkeypatch.setattr(goden.GodenClient, "transport", httpx.MockTransport(handler))
        return calls

    return install


def test_confirmed_checks_pair_and_caches_list(migom):
    calls = migom(lambda request: httpx.Response(200, json=[{"point_id": str(POINT), "outlet_id": 7}]))
    assert asyncio.run(goden.confirmed(POINT, 7))
    # к точке подключено другое заведение
    assert not asyncio.run(goden.confirmed(POINT, 8))
    assert calls == {"tokens": 1, "points": 1}


def test_revoked_token_is_requested_again(migom):
    def handler(request: httpx.Request) -> httpx.Response:
        if request.headers["Authorization"] == "Bearer token-1":
            return httpx.Response(401)
        return httpx.Response(200, json={"items": [{"dish": {"id": "d", "name": "Паста"}, "available": True}], "total": 1})

    calls = migom(handler)
    menu = asyncio.run(goden.as_migom(lambda client: client.menu(POINT)))
    assert menu[0]["available"]
    assert calls["tokens"] == 2


def test_network_failure_is_unavailable():
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("refused")

    with pytest.raises(goden.GodenUnavailableError):
        asyncio.run(_client(handler).owned_points())
