from fastapi import status
from fastapi.exceptions import HTTPException


class OutletNotFoundError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Торговая точка не найдена",
        )


class OutletAccessDeniedError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Нет доступа к этой торговой точке",
        )


class ManagerAlreadyExistsError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail="Этот пользователь уже является менеджером данной точки",
        )


class ManagerNotFoundError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Менеджер не найден на данной точке",
        )


class InvalidManagerRoleError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Пользователь должен иметь роль 'outlet_manager'",
        )
