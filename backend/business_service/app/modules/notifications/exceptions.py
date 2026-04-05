from fastapi import status
from fastapi.exceptions import HTTPException


class NotificationNotFoundError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Уведомление не найдено",
        )


class NotificationAccessDeniedError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Нет доступа к этому уведомлению",
        )
