from datetime import datetime

from pydantic import BaseModel, EmailStr, field_validator


class RoleResponse(BaseModel):
    id: int
    name: str

    model_config = {"from_attributes": True}


class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    phone: str | None
    avatar_url: str | None
    is_active: bool
    role: RoleResponse
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class UserUpdateMe(BaseModel):
    """Что пользователь может менять сам."""
    full_name: str | None = None
    phone: str | None = None


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Пароль должен содержать минимум 8 символов")
        return v


class UserListResponse(BaseModel):
    items: list[UserResponse]
    total: int
