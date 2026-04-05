from datetime import datetime, timedelta, timezone

import bcrypt
from jose import JWTError, jwt

from app.config import settings


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


def _create_token(
    subject: int, role: str, token_type: str, expire_delta: timedelta,
    outlet_id: int | None = None,
) -> str:
    expire = datetime.now(timezone.utc) + expire_delta
    payload = {
        "sub": str(subject),
        "role": role,
        "type": token_type,
        "exp": expire,
    }
    if outlet_id is not None:
        payload["outlet_id"] = outlet_id
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_access_token(user_id: int, role: str, outlet_id: int | None = None) -> str:
    return _create_token(
        subject=user_id,
        role=role,
        token_type="access",
        expire_delta=timedelta(minutes=settings.jwt_access_expire_minutes),
        outlet_id=outlet_id,
    )


def create_refresh_token(user_id: int, role: str, outlet_id: int | None = None) -> str:
    return _create_token(
        subject=user_id,
        role=role,
        token_type="refresh",
        expire_delta=timedelta(days=settings.jwt_refresh_expire_days),
        outlet_id=outlet_id,
    )


def decode_token(token: str) -> dict:
    """Декодирует JWT. Выбрасывает JWTError если токен невалиден или истёк."""
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
