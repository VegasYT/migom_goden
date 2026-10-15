from pydantic import BaseModel, EmailStr, field_validator


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    phone: str | None = None
    role_id: int = 1

    @field_validator("password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Пароль должен содержать минимум 8 символов")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str | None = None


class IdentityResponse(BaseModel):
    """Кто владелец токена: нужен realtime_service, который сам в базу не ходит."""
    user_id: int
    role: str
    outlet_id: int | None = None


class RoleResponse(BaseModel):
    id: int
    name: str
    is_assignable: bool

    model_config = {"from_attributes": True}


class SessionRequest(BaseModel):
    """Роль нового пользователя: её выбирает кабинет при первом входе. Существующему не нужна."""
    role_id: int | None = None
    phone: str | None = None
