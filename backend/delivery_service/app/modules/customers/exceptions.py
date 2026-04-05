from app.core.exceptions import ForbiddenError, NotFoundError


class AddressNotFoundError(NotFoundError):
    def __init__(self):
        super().__init__("Адрес не найден")


class AddressAccessDeniedError(ForbiddenError):
    def __init__(self):
        super().__init__("Адрес принадлежит другому пользователю")


class PaymentMethodNotFoundError(NotFoundError):
    def __init__(self):
        super().__init__("Способ оплаты не найден")


class PaymentMethodAccessDeniedError(ForbiddenError):
    def __init__(self):
        super().__init__("Способ оплаты принадлежит другому пользователю")
