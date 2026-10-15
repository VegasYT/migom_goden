from app.core.exceptions import BadRequestError, ConflictError, ForbiddenError, NotFoundError


class OrderNotFoundError(NotFoundError):
    def __init__(self):
        super().__init__("Заказ не найден")


class OrderAccessDeniedError(ForbiddenError):
    def __init__(self):
        super().__init__("Нет доступа к этому заказу")


class OrderInvalidStatusError(BadRequestError):
    def __init__(self, detail: str = "Недопустимый переход статуса"):
        super().__init__(detail)


class CartEmptyError(BadRequestError):
    def __init__(self):
        super().__init__("Корзина пуста")


class OutletNotFoundError(NotFoundError):
    def __init__(self):
        super().__init__("Торговая точка не найдена или неактивна")


class OutletClosedError(BadRequestError):
    def __init__(self):
        super().__init__("Торговая точка сейчас закрыта")


class MinOrderPriceError(BadRequestError):
    def __init__(self, min_price: int):
        super().__init__(f"Минимальная сумма заказа: {min_price} ₽")


class DeliveryAddressRequiredError(BadRequestError):
    def __init__(self):
        super().__init__("Для доставки необходимо указать адрес (customer_address_id или координаты)")


class DeliveryZoneError(BadRequestError):
    def __init__(self):
        super().__init__("Адрес доставки не входит в зону обслуживания точки")


class PaymentMethodNotFoundError(NotFoundError):
    def __init__(self):
        super().__init__("Способ оплаты не найден или не принадлежит вам")


class CourierNotOnShiftError(BadRequestError):
    def __init__(self):
        super().__init__("Курьер не в активной смене")


class CourierHasActiveOrderError(BadRequestError):
    def __init__(self):
        super().__init__("У курьера уже есть активный заказ")


class CourierOutOfZoneError(BadRequestError):
    def __init__(self):
        super().__init__("Адрес доставки не входит в геозоны курьера")


class PickupOnlyError(BadRequestError):
    def __init__(self):
        super().__init__("Это заказ самовывоза - курьер не назначается")


class OrderNotOfferedError(BadRequestError):
    def __init__(self):
        super().__init__("Этот заказ не предложен вам или время оффера истекло")


class ProductsShortageError(ConflictError):
    def __init__(self, products: list[str]):
        names = ", ".join(products) if products else "часть продуктов"
        super().__init__(f"Заведению не хватает продуктов: {names}. Уменьшите количество или выберите другие блюда")


class ItemNotSoldError(ConflictError):
    def __init__(self, name: str):
        super().__init__(f'Товар "{name}" сейчас не продаётся в этом заведении')


class OutletNotAcceptingError(ConflictError):
    def __init__(self):
        super().__init__("Заведение сейчас не принимает заказы")


class UnavailableItemsError(ConflictError):
    """Goden отказал в заказе: блюда корзины, которых не хватает, с тем, сколько можно заказать."""

    def __init__(self, items: list[str]):
        super().__init__(f"Пока вы оформляли заказ, изменилось наличие: {'; '.join(items)}. Измените корзину")
