from fastapi import status
from fastapi.exceptions import HTTPException


class InvalidCredentialsError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный email или пароль",
            headers={"WWW-Authenticate": "Bearer"},
        )


class UserAlreadyExistsError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail="Пользователь с таким email уже существует",
        )


class InvalidTokenError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Токен недействителен или истёк",
            headers={"WWW-Authenticate": "Bearer"},
        )


class UserInactiveError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Аккаунт заблокирован",
        )


class RoleNotAssignableError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Указанная роль недоступна для самостоятельного выбора",
        )


class PhoneAlreadyExistsError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail="Пользователь с таким номером телефона уже существует",
        )
