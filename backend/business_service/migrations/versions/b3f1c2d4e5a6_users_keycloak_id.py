"""users: id в Keycloak, пароль больше не обязателен

Revision ID: b3f1c2d4e5a6
Revises: 7cdb03b28321
Create Date: 2026-10-14 23:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'b3f1c2d4e5a6'
down_revision: Union[str, None] = '7cdb03b28321'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column('keycloak_id', sa.String(length=36), nullable=True))
    op.create_unique_constraint('users_keycloak_id_key', 'users', ['keycloak_id'])
    # у пользователей, заведённых через Keycloak, пароля в Мигоме нет
    op.alter_column('users', 'password_hash', existing_type=sa.String(length=255), nullable=True)


def downgrade() -> None:
    op.alter_column('users', 'password_hash', existing_type=sa.String(length=255), nullable=False)
    op.drop_constraint('users_keycloak_id_key', 'users', type_='unique')
    op.drop_column('users', 'keycloak_id')
