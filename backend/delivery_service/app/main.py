import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from redis.asyncio import Redis

from app.config import settings
from app.core import kafka
from app.core.offer_worker import watch_expired_offers

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Redis
    app.state.redis = Redis.from_url(
        settings.redis_url,
        encoding="utf-8",
        decode_responses=True,
    )
    logger.info("Redis подключён")

    # Kafka producer
    await kafka.start_producer()

    # Фоновый воркер: предложение заказов курьерам при истечении оффера
    offer_task = asyncio.create_task(watch_expired_offers(app.state.redis))
    logger.info("offer_worker запущен")

    yield

    # Завершение
    offer_task.cancel()
    try:
        await offer_task
    except asyncio.CancelledError:
        pass
    await app.state.redis.aclose()
    await kafka.stop_producer()


app = FastAPI(
    title="Migom - Delivery Service",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/delivery/docs",
    redoc_url="/delivery/redoc",
    openapi_url="/delivery/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.modules.couriers.router import router as couriers_router
from app.modules.shifts.router import router as shifts_router
from app.modules.customers.router import router as customers_router
from app.modules.cart.router import router as cart_router
from app.modules.orders.router import router as orders_router

app.include_router(couriers_router, prefix="/api/v1")
app.include_router(shifts_router, prefix="/api/v1")
app.include_router(customers_router, prefix="/api/v1")
app.include_router(cart_router, prefix="/api/v1")
app.include_router(orders_router, prefix="/api/v1")


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}
