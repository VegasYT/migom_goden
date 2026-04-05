from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from redis.asyncio import Redis

from app.config import settings
from app.core import cache
# Импорт всех моделей чтобы SQLAlchemy видел их при конфигурации relationship
from app.modules.users.models import Role, User  # noqa
from app.modules.companies.models import Company  # noqa
from app.modules.catalog.models import CatalogCategory, CatalogItem, CuisineTag, CompanyCuisineTag  # noqa
from app.modules.outlets.models import Outlet, OutletItemAvailability, OutletManager  # noqa
from app.modules.reviews.models import Review  # noqa
from app.modules.discounts.models import Discount, PromoCode  # noqa
from app.modules.notifications.models import Notification  # noqa
from app.modules.promo.models import PromoBanner  # noqa

from app.modules.auth.router import router as auth_router
from app.modules.companies.router import router as companies_router
from app.modules.catalog.router import router as catalog_router
from app.modules.outlets.router import router as outlets_router
from app.modules.users.router import router as users_router
from app.modules.reviews.router import router as reviews_router
from app.modules.discounts.router import router as discounts_router
from app.modules.notifications.router import router as notifications_router
from app.modules.promo.router import router as promo_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Подключение к Redis при старте
    cache.redis_client = Redis.from_url(
        settings.redis_url,
        encoding="utf-8",
        decode_responses=True,
    )
    yield
    # Закрытие соединения при остановке
    await cache.redis_client.aclose()


app = FastAPI(
    title="Migom - Business Service",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/business/docs",
    redoc_url="/business/redoc",
    openapi_url="/business/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api/v1")
app.include_router(companies_router, prefix="/api/v1")
app.include_router(catalog_router, prefix="/api/v1")
app.include_router(outlets_router, prefix="/api/v1")
app.include_router(users_router, prefix="/api/v1")
app.include_router(reviews_router, prefix="/api/v1")
app.include_router(discounts_router, prefix="/api/v1")
app.include_router(notifications_router, prefix="/api/v1")
app.include_router(promo_router, prefix="/api/v1")


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok"}
