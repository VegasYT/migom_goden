"""Какие блюда отказанного заказа не проходят по меню точки Goden."""
import asyncio
import uuid
from collections import Counter

import pytest

from app.core import goden
from app.modules.orders.exceptions import UnavailableItemsError
from app.modules.orders.service import OrderService, unavailable_items

PIZZA, PASTA, SOUP = (uuid.uuid4() for _ in range(3))
NAMES = {PIZZA: "Маргарита", PASTA: "Паста", SOUP: "Суп"}


def dish(id, portions, available=True):
    return {"dish": {"id": str(id), "name": "-"}, "available": available, "portions": portions}


def test_unavailable_items():
    menu = [dish(PIZZA, 0, available=False), dish(PASTA, 1), dish(SOUP, 5)]
    # суп в меню есть и его хватает, второго супа заказали - тоже хватает
    assert unavailable_items(Counter({PIZZA: 2, PASTA: 3, SOUP: 2}), NAMES, menu) == [
        "Маргарита - нет в наличии", "Паста - можно не больше 1"]


def test_dish_off_the_menu_is_unavailable():
    assert unavailable_items(Counter({PIZZA: 1}), NAMES, []) == ["Маргарита - нет в наличии"]


def test_everything_is_back():
    assert unavailable_items(Counter({PASTA: 1}), NAMES, [dish(PASTA, 1)]) == []


def test_message():
    error = UnavailableItemsError(["Маргарита - нет в наличии", "Паста - можно не больше 1"])
    assert error.detail == ("Пока вы оформляли заказ, изменилось наличие: Маргарита - нет в наличии; "
                            "Паста - можно не больше 1. Измените корзину")


def refuse(monkeypatch, menu):
    """Ответ на отказ Goden при заказе двух пицц; menu - меню точки или исключение при его чтении."""
    async def read(point_id):
        if isinstance(menu, Exception):
            raise menu
        return menu

    monkeypatch.setattr(goden, "menu", read)
    service = OrderService(None, None, None, None, None, None, None)
    with pytest.raises(Exception) as refused:
        asyncio.run(service._refuse_unavailable(uuid.uuid4(), Counter({PIZZA: 2}), NAMES, ["Тесто"]))
    return refused.value.detail


def test_refusal_names_dishes(monkeypatch):
    assert "Маргарита - можно не больше 1" in refuse(monkeypatch, [dish(PIZZA, 1)])


def test_refusal_without_menu_names_products(monkeypatch):
    assert "Тесто" in refuse(monkeypatch, goden.GodenUnavailableError())
    assert "Тесто" in refuse(monkeypatch, [dish(PIZZA, 5)])
