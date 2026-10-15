"""Изменение адреса покупателя: поле address меняется как остальные."""
import asyncio
from types import SimpleNamespace

from app.modules.customers.repository import AddressRepository


class FakeSession:
    async def flush(self):
        pass


def test_update_changes_address_field():
    address = SimpleNamespace(address='Москва', latitude=55.7, label='Дом')
    updated = asyncio.run(AddressRepository(FakeSession()).update(address, address='Ростов-на-Дону', latitude=47.2))
    assert (updated.address, updated.latitude, updated.label) == ('Ростов-на-Дону', 47.2, 'Дом')
