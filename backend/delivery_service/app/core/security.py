from jose import jwt

from app.config import settings


def decode_token(token: str) -> dict:
    """Декодирует JWT выпущенный business_service. Выбрасывает JWTError если токен невалиден или истёк."""
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
