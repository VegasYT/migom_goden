"""orders: точка и заказ Goden

Revision ID: d5e6f7a8b9c0
Revises: 2c9cf3b1a20c
Create Date: 2026-10-15 02:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = 'd5e6f7a8b9c0'
down_revision: Union[str, None] = '2c9cf3b1a20c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('orders', sa.Column('goden_point_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column('orders', sa.Column('goden_order_id', postgresql.UUID(as_uuid=True), nullable=True))


def downgrade() -> None:
    op.drop_column('orders', 'goden_order_id')
    op.drop_column('orders', 'goden_point_id')
