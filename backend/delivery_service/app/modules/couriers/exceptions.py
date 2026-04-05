from app.core.exceptions import BadRequestError, ForbiddenError, NotFoundError


class CourierNotFoundError(NotFoundError):
    def __init__(self):
        super().__init__("Курьер не найден")


class CourierBlockedError(ForbiddenError):
    def __init__(self):
        super().__init__("Курьер заблокирован")



class CourierAlreadyBlockedError(BadRequestError):
    def __init__(self):
        super().__init__("Курьер уже заблокирован")


class CourierAlreadyUnblockedError(BadRequestError):
    def __init__(self):
        super().__init__("Курьер уже разблокирован")
