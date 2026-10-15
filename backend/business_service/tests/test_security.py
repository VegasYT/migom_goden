"""Проверка access-токенов Keycloak без сети: ключи realm подменяются ключом теста."""
import asyncio
import time

import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from jose import JWTError, jwk, jwt

from app.core import security

ISSUER = "http://localhost:8180/realms/goden"


def _key_pair():
    private = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem = private.private_bytes(
        serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()
    )
    public = jwk.construct(private.public_key().public_bytes(
        serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo
    ), "RS256").to_dict()
    return pem, public


REALM_KEY, REALM_PUBLIC = _key_pair()
OTHER_KEY, _ = _key_pair()


@pytest.fixture(autouse=True)
def realm_keys():
    security._keys = {"realm-key": {**REALM_PUBLIC, "kid": "realm-key"}}
    # ключи только что загружены: неизвестный kid не пойдёт в сеть
    security._keys_loaded_at = time.monotonic()


def _token(key=REALM_KEY, kid="realm-key", **overrides):
    claims = {
        "sub": "8f2c", "iss": ISSUER, "aud": ["migom-api", "account"], "typ": "Bearer",
        "exp": int(time.time()) + 300, **overrides,
    }
    return jwt.encode(claims, key, algorithm="RS256", headers={"kid": kid})


def _decode(token):
    return asyncio.run(security.decode_token(token))


def test_access_token_of_realm():
    assert _decode(_token())["sub"] == "8f2c"


@pytest.mark.parametrize("token", [
    pytest.param(_token(aud="goden-api"), id="токен Goden"),
    pytest.param(_token(iss="http://evil/realms/goden"), id="чужой издатель"),
    pytest.param(_token(exp=int(time.time()) - 60), id="истёк"),
    pytest.param(_token(typ="Refresh"), id="refresh-токен"),
    pytest.param(_token(key=OTHER_KEY), id="подписан другим ключом"),
    pytest.param(_token(kid="unknown"), id="неизвестный ключ"),
    pytest.param("not-a-token", id="мусор"),
])
def test_rejected(token):
    with pytest.raises(JWTError):
        _decode(token)
