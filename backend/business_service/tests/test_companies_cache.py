import asyncio
import fnmatch
from datetime import datetime
from types import SimpleNamespace

from app.modules.companies import service as companies


class _Repo:
    def __init__(self, names):
        self.names = names

    async def list_all(self, offset, limit, search=None):

        items = [SimpleNamespace(id=i, owner_id=1, name=n, description=None, cover_url=None, is_active=True, is_blocked=False,
                                 created_at=datetime(2026, 1, 1), updated_at=datetime(2026, 1, 1))
                 for i, n in enumerate(self.names, 1)]
        return items[offset:offset + limit], len(items)


def test_page_with_small_limit_does_not_replace_full_list(monkeypatch):
    store = {}

    async def get(key):
        return store.get(key)

    async def put(key, value, ttl=300):
        store[key] = value

    async def drop(pattern):
        for key in [k for k in store if fnmatch.fnmatch(k, pattern)]:
            del store[key]

    monkeypatch.setattr(companies, "cache_get", get)
    monkeypatch.setattr(companies, "cache_set", put)
    monkeypatch.setattr(companies, "cache_delete_pattern", drop)
    service = companies.CompanyService(_Repo(["KFC", "Пиццерия"]))

    async def run():
        # модераторская панель берёт одну компанию ради total
        assert len((await service.list_companies(offset=0, limit=1)).items) == 1
        assert [c.name for c in (await service.list_companies(offset=0, limit=20)).items] == ["KFC", "Пиццерия"]
        await drop(companies._CACHE_PATTERN)
        assert store == {}

    asyncio.run(run())
