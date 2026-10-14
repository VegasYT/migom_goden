import time

import httpx
from jose import JWTError, jwt

from app.config import settings

# Ключи подписи realm: загружаются при первом токене, неизвестный kid перезагружает их
# не чаще раза в минуту, чтобы пережить смену ключей Keycloak.
_KEYS_RELOAD_INTERVAL = 60
_keys: dict[str, dict] = {}
_keys_loaded_at = float("-inf")


async def _signing_key(kid: str | None) -> dict:
    global _keys, _keys_loaded_at
    if kid not in _keys and time.monotonic() - _keys_loaded_at >= _KEYS_RELOAD_INTERVAL:
        async with httpx.AsyncClient(timeout=5) as client:
            response = await client.get(f"{settings.keycloak_realm_url}/protocol/openid-connect/certs")
            response.raise_for_status()
        _keys = {key["kid"]: key for key in response.json()["keys"] if key.get("use", "sig") == "sig"}
        _keys_loaded_at = time.monotonic()
    key = _keys.get(kid)
    if key is None:
        raise JWTError("неизвестный ключ подписи")
    return key


async def decode_token(token: str) -> dict:
    """Проверяет access-токен Keycloak: подпись, срок, издатель и получатель.

    JWTError - токен не годится; httpx.HTTPError - ключи realm не загрузились.
    """
    key = await _signing_key(jwt.get_unverified_header(token).get("kid"))
    claims = jwt.decode(
        token, key, algorithms=["RS256"],
        audience=settings.keycloak_audience, issuer=settings.keycloak_issuer,
    )
    # refresh- и id-токены подписаны тем же ключом, но API принимает только access
    if claims.get("typ") != "Bearer":
        raise JWTError("ожидается access-токен")
    return claims
