"""roles: справочник ролей заполняется миграцией

Revision ID: d1e2f3a4b5c6
Revises: c4d2e3f5a6b7
Create Date: 2026-10-15 12:00:00

"""
from typing import Sequence, Union

from alembic import op


revision: str = 'd1e2f3a4b5c6'
down_revision: Union[str, None] = 'c4d2e3f5a6b7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # без ролей не работает регистрация; на базе, где их уже завели вручную, ничего не меняется
    op.execute(
        "INSERT INTO roles (id, name, is_assignable) VALUES "
        "(1, 'customer', true), (2, 'owner', true), (3, 'courier', true), "
        "(4, 'moderator', false), (5, 'outlet_manager', true) "
        "ON CONFLICT (id) DO NOTHING"
    )


def downgrade() -> None:
    # на роли ссылаются пользователи: справочник при откате остаётся
    pass
