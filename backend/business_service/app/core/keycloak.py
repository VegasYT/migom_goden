"""Обращения к Keycloak от имени клиента migom-backend: вход по паролю, обновление и отзыв
токенов, учётные записи через Admin API (сервисная учётная запись клиента)."""

import time

import httpx
from fastapi import HTTPException, status
from jose import jwt

from app.config import settings


class KeycloakUnavailableError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Сервис входа временно недоступен",
        )


class KeycloakRejectedError(Exception):
    """Keycloak отклонил пароль или refresh-токен."""


class KeycloakUserExistsError(Exception):
    """В realm уже есть пользователь с такой почтой."""


_TIMEOUT = 10
_admin_token: str | None = None
_admin_token_expires_at = 0.0


def _token_url() -> str:
    return f"{settings.keycloak_realm_url}/protocol/openid-connect"


def _admin_url() -> str:
    # http://host/realms/goden -> http://host/admin/realms/goden
    return settings.keycloak_realm_url.replace("/realms/", "/admin/realms/", 1)


def _client_form() -> dict[str, str]:
    return {"client_id": settings.keycloak_client_id, "client_secret": settings.keycloak_client_secret}


async def _post_form(url: str, form: dict[str, str]) -> httpx.Response:
    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            return await client.post(url, data=form)
    except httpx.HTTPError as e:
        raise KeycloakUnavailableError() from e


async def _tokens(form: dict[str, str]) -> dict:
    response = await _post_form(f"{_token_url()}/token", {**_client_form(), **form})
    # invalid_grant: неверный пароль, нет пользователя, просроченный или отозванный refresh-токен
    if response.status_code in (400, 401) and response.json().get("error") == "invalid_grant":
        raise KeycloakRejectedError()
    if response.status_code != 200:
        raise KeycloakUnavailableError()
    return response.json()


async def password_grant(email: str, password: str) -> dict:
    return await _tokens({"grant_type": "password", "username": email, "password": password})


async def refresh_grant(refresh_token: str) -> dict:
    return await _tokens({"grant_type": "refresh_token", "refresh_token": refresh_token})


async def logout(refresh_token: str) -> None:
    await _post_form(f"{_token_url()}/logout", {**_client_form(), "refresh_token": refresh_token})


def subject_of(access_token: str) -> str:
    """sub токена, который только что выдал Keycloak: подпись тут проверять незачем."""
    return jwt.get_unverified_claims(access_token)["sub"]


async def _admin_headers() -> dict[str, str]:
    global _admin_token, _admin_token_expires_at
    if _admin_token is None or time.monotonic() >= _admin_token_expires_at:
        tokens = await _tokens({"grant_type": "client_credentials"})
        _admin_token = tokens["access_token"]
        _admin_token_expires_at = time.monotonic() + tokens["expires_in"] - 30
    return {"Authorization": f"Bearer {_admin_token}"}


async def _admin(method: str, path: str, **kwargs) -> httpx.Response:
    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT) as client:
            response = await client.request(method, f"{_admin_url()}{path}", headers=await _admin_headers(), **kwargs)
    except httpx.HTTPError as e:
        raise KeycloakUnavailableError() from e
    if response.status_code >= 500 or response.status_code in (401, 403):
        raise KeycloakUnavailableError()
    return response


async def find_user_id(email: str) -> str | None:
    response = await _admin("GET", "/users", params={"email": email, "exact": "true"})
    users = response.json()
    return users[0]["id"] if users else None


def _names(full_name: str) -> tuple[str, str]:
    # Keycloak 26 не пускает пользователя без имени и фамилии
    parts = full_name.split(maxsplit=1)
    if not parts:
        return "-", "-"
    return parts[0], parts[1] if len(parts) > 1 else "-"


async def create_user(email: str, password: str, full_name: str) -> str:
    first_name, last_name = _names(full_name)
    response = await _admin("POST", "/users", json={
        "username": email, "email": email, "enabled": True, "emailVerified": True,
        "firstName": first_name, "lastName": last_name,
        "credentials": [{"type": "password", "value": password, "temporary": False}],
    })
    if response.status_code == 409:
        raise KeycloakUserExistsError()
    if response.status_code != 201:
        raise KeycloakUnavailableError()
    return response.headers["Location"].rsplit("/", 1)[1]


async def delete_user(keycloak_id: str) -> None:
    await _admin("DELETE", f"/users/{keycloak_id}")


async def set_password(keycloak_id: str, password: str) -> None:
    response = await _admin("PUT", f"/users/{keycloak_id}/reset-password", json={
        "type": "password", "value": password, "temporary": False,
    })
    if response.status_code != 204:
        raise KeycloakUnavailableError()
