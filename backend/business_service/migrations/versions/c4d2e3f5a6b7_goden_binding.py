"""outlets и catalog_items: связь с точкой и блюдом Goden

Revision ID: c4d2e3f5a6b7
Revises: b3f1c2d4e5a6
Create Date: 2026-10-15 12:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = 'c4d2e3f5a6b7'
down_revision: Union[str, None] = 'b3f1c2d4e5a6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('outlets', sa.Column('goden_point_id', postgresql.UUID(as_uuid=True), nullable=True))
    # точка Goden связана не больше чем с одним заведением
    op.create_index('uq_outlets_goden_point', 'outlets', ['goden_point_id'], unique=True,
                    postgresql_where=sa.text('goden_point_id IS NOT NULL'))
    op.add_column('catalog_items', sa.Column('goden_dish_id', postgresql.UUID(as_uuid=True), nullable=True))
    # блюдо Goden связано не больше чем с одним товаром компании
    op.create_index('uq_catalog_items_goden_dish', 'catalog_items', ['company_id', 'goden_dish_id'], unique=True,
                    postgresql_where=sa.text('goden_dish_id IS NOT NULL'))


def downgrade() -> None:
    op.drop_index('uq_catalog_items_goden_dish', table_name='catalog_items')
    op.drop_column('catalog_items', 'goden_dish_id')
    op.drop_index('uq_outlets_goden_point', table_name='outlets')
    op.drop_column('outlets', 'goden_point_id')
