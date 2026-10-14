"""Клиент заказов Goden без сети: Keycloak и Goden подменяет httpx.MockTransport."""
import asyncio
import json
import os
import uuid

# настройки читаются при импорте app.config; тесту база не нужна
os.environ.update({
    "DB_HOST": "-", "DB_NAME": "-", "DB_USER": "-", "DB_PASSWORD": "-",
    "KEYCLOAK_REALM_URL": "http://keycloak/realms/goden",
    "KEYCLOAK_ISSUER": "http://localhost:8180/realms/goden",
    "GODEN_API_URL": "http://goden/api/v1",
    "GODEN_CLIENT_SECRET": "integration-secret",
})

import httpx  # noqa: E402
import pytest  # noqa: E402

from app.core import goden  # noqa: E402

POINT = uuid.UUID("0198c0de-0000-7000-8000-000000000012")
DISH = uuid.UUID("0198c0de-0000-7000-8000-0000000000d1")


@pytest.fixture
def server(monkeypatch):
    """Keycloak выдаёт токены по порядку, остальные запросы отвечает handler; requests - запросы к Goden."""
    monkeypatch.setattr(goden, "_token", None)
    monkeypatch.setattr(goden, "_pairs_loaded_at", 0.0)
    state = {"tokens": 0, "requests": []}

    def install(goden_handler):
        def handler(request: httpx.Request) -> httpx.Response:
            if request.url.path.endswith("/protocol/openid-connect/token"):
                form = dict(httpx.QueryParams(request.content.decode()))
                assert (form["grant_type"], form["client_id"], form["client_secret"]) == (
                    "client_credentials", "migom-integration", "integration-secret")
                state["tokens"] += 1
                return httpx.Response(200, json={"access_token": f"token-{state['tokens']}", "expires_in": 300})
            state["requests"].append(request)
            return goden_handler(request)

        monkeypatch.setattr(goden, "transport", httpx.MockTransport(handler))
        return state

    return install


def test_place_order_sends_portions_with_key(server):
    state = server(lambda request: httpx.Response(201, json={"id": "o", "status": "accepted", "shortages": []}))
    placed = asyncio.run(goden.place_order(POINT, {DISH: 3}))
    assert placed["status"] == "accepted"
    request = state["requests"][0]
    assert request.url.path == f"/api/v1/points/{POINT}/orders"
    assert request.headers["Authorization"] == "Bearer token-1"
    assert request.headers["Idempotency-Key"]
    assert json.loads(request.content) == {"items": [{"dish_id": str(DISH), "portions": 3}]}


def test_lost_answer_is_retried_with_same_key(server):
    attempts = []

    def handler(request: httpx.Request) -> httpx.Response:
        attempts.append(request.headers["Idempotency-Key"])
        if len(attempts) == 1:
            return httpx.Response(502)
        return httpx.Response(201, json={"id": "o", "status": "accepted", "shortages": []})

    server(handler)
    asyncio.run(goden.place_order(POINT, {DISH: 1}))
    assert len(attempts) == 2 and attempts[0] == attempts[1]


def test_refused_and_unavailable(server):
    server(lambda request: httpx.Response(403))
    with pytest.raises(goden.GodenRefusedError) as refused:
        asyncio.run(goden.cancel_order(POINT, DISH))
    assert refused.value.status_code == 403

    server(lambda request: httpx.Response(500))
    with pytest.raises(goden.GodenUnavailableError):
        asyncio.run(goden.place_order(POINT, {DISH: 1}))


def test_revoked_token_is_requested_again(server):
    def handler(request: httpx.Request) -> httpx.Response:
        if request.headers["Authorization"] == "Bearer token-1":
            return httpx.Response(401)
        return httpx.Response(200, json=[{"point_id": str(POINT), "outlet_id": 7}])

    state = server(handler)
    assert asyncio.run(goden.confirmed(POINT, 7))
    assert not asyncio.run(goden.confirmed(POINT, 8))
    # второй вызов взял пары из кеша
    assert state["tokens"] == 2 and len(state["requests"]) == 2
