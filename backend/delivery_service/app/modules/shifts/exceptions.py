from app.core.exceptions import BadRequestError, NotFoundError


class ShiftAlreadyActiveError(BadRequestError):
    def __init__(self):
        super().__init__("У вас уже есть активная смена")


class NoActiveShiftError(BadRequestError):
    def __init__(self):
        super().__init__("Нет активной смены")


class ShiftNotFoundError(NotFoundError):
    def __init__(self):
        super().__init__("Смена не найдена")


class CannotEndShiftWithActiveOrderError(BadRequestError):
    def __init__(self):
        super().__init__("Нельзя завершить смену: есть активный заказ")
