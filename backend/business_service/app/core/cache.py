import json
from typing import Any

from redis.asyncio import Redis

from app.config import settings

# Глобальный клиент, инициализируется в lifespan
redis_client: Redis | None = None


def get_redis() -> Redis:
    if redis_client is None:
        raise RuntimeError("Redis не инициализирован")
    return redis_client


async def cache_get(key: str) -> Any | None:
    client = get_redis()
    value = await client.get(key)
    if value is None:
        return None
    return json.loads(value)


async def cache_set(key: str, value: Any, ttl: int = 300) -> None:
    client = get_redis()
    await client.set(key, json.dumps(value), ex=ttl)


async def cache_delete(key: str) -> None:
    client = get_redis()
    await client.delete(key)


async def cache_delete_pattern(pattern: str) -> None:
    client = get_redis()
    keys = await client.keys(pattern)
    if keys:
        await client.delete(*keys)
