import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy.ext.asyncio import create_async_engine

from app.config import settings
from app.db.base import Base

# Импортируем все модели чтобы Alembic видел их при autogenerate
from app.modules.couriers.models import Courier  # noqa
from app.modules.shifts.models import Shift  # noqa
from app.modules.customers.models import CustomerAddress, CustomerPaymentMethod  # noqa
from app.modules.cart.models import BucketItem  # noqa
from app.modules.orders.models import Order, OrderItem, OrderStatusHistory  # noqa

config = context.config
config.set_main_option("sqlalchemy.url", settings.db_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

# Таблицы, которыми управляет delivery_service
DELIVERY_TABLES = {
    "couriers",
    "shifts",
    "customer_addresses",
    "customer_payment_methods",
    "bucket_items",
    "orders",
    "order_items",
    "order_status_history",
}


def include_name(name, type_, parent_names):
    """Ограничиваем autogenerate только таблицами delivery_service."""
    if type_ == "table":
        return name in DELIVERY_TABLES
    return True


def run_migrations_offline() -> None:
    context.configure(
        url=settings.db_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        version_table="alembic_version_delivery",
        include_name=include_name,
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection):
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        version_table="alembic_version_delivery",
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
