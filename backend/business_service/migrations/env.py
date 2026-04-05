import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy.ext.asyncio import create_async_engine

from app.config import settings
from app.db.base import Base

# Импортируем все модели, чтобы Alembic их видел при автогенерации
from app.modules.users.models import Role, User  # noqa
from app.modules.companies.models import Company  # noqa
from app.modules.catalog.models import CatalogCategory, CatalogItem, CuisineTag, CompanyCuisineTag  # noqa
from app.modules.outlets.models import Outlet, OutletItemAvailability, OutletManager  # noqa
from app.modules.reviews.models import Review  # noqa
from app.modules.discounts.models import Discount, PromoCode  # noqa
from app.modules.notifications.models import Notification  # noqa
from app.modules.promo.models import PromoBanner  # noqa

config = context.config
config.set_main_option("sqlalchemy.url", settings.db_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

# Таблицы принадлежащие business_service - только их трогаем при autogenerate
BUSINESS_TABLES = {
    "roles", "users", "companies", "company_cuisine_tags", "cuisine_tags",
    "catalog_categories", "catalog_items", "outlets", "outlet_item_availability",
    "outlet_managers", "reviews", "discounts", "promo_codes", "promo_banners", "notifications",
}


def include_name(name, type_, parent_names):
    if type_ == "table":
        return name in BUSINESS_TABLES
    return True


def run_migrations_offline() -> None:
    context.configure(
        url=settings.db_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        version_table="alembic_version_business",
        include_name=include_name,
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection):
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        version_table="alembic_version_business",
        include_name=include_name,
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online() -> None:
    engine = create_async_engine(settings.db_url)
    async with engine.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await engine.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())
