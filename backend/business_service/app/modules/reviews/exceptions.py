from fastapi import status
from fastapi.exceptions import HTTPException


class ReviewNotFoundError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Отзыв не найден",
        )


class ReviewAccessDeniedError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Нет доступа к этому отзыву",
        )


class ReviewAlreadyExistsError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail="Отзыв для этого заказа уже существует",
        )
