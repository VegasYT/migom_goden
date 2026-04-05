from app.core.exceptions import BadRequestError, ForbiddenError, NotFoundError


class CartNotFoundError(NotFoundError):
    def __init__(self):
        super().__init__("Корзина для данной компании не найдена")


class CartItemNotFoundError(NotFoundError):
    def __init__(self):
        super().__init__("Позиция в корзине не найдена")


class CartItemAccessDeniedError(ForbiddenError):
    def __init__(self):
        super().__init__("Позиция принадлежит другому покупателю")


class CatalogItemNotFoundError(NotFoundError):
    def __init__(self):
        super().__init__("Товар не найден или недоступен")
