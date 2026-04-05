from fastapi import status
from fastapi.exceptions import HTTPException


class DiscountNotFoundError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Скидка не найдена",
        )


class PromoCodeNotFoundError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Промокод не найден",
        )


class PromoCodeExpiredError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_410_GONE,
            detail="Промокод истёк или исчерпан",
        )
