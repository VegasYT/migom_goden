"""Вход в веб-кабинет по токену Keycloak: пользователь Мигома, регистрация при первом входе, связь по почте."""
import asyncio
from types import SimpleNamespace

import pytest

from app.modules.auth.exceptions import (
    AccountLinkRequiredError,
    RegistrationRequiredError,
    RoleNotAssignableError,
)
from app.modules.auth.schemas import SessionRequest
from app.modules.auth.service import AuthService

ROLES = {2: SimpleNamespace(id=2, is_assignable=True), 4: SimpleNamespace(id=4, is_assignable=False)}


class FakeUsers:
    def __init__(self, *users):
        self.users = list(users)

    async def get_by_keycloak_id(self, keycloak_id):
        return next((u for u in self.users if u.keycloak_id == keycloak_id), None)

    async def get_by_email(self, email):
        return next((u for u in self.users if u.email == email), None)

    async def link_keycloak(self, user, keycloak_id):
        user.keycloak_id = keycloak_id

    async def get_role_by_id(self, role_id):
        return ROLES.get(role_id)

    async def create(self, email, keycloak_id, full_name, role_id, phone=None):
        user = SimpleNamespace(email=email, keycloak_id=keycloak_id, full_name=full_name, role_id=role_id,
                               phone=phone, is_active=True)
        self.users.append(user)
        return user


def user(email, keycloak_id=None):
    return SimpleNamespace(email=email, keycloak_id=keycloak_id, is_active=True)


def claims(email='new@example.com', verified=False, sub='kc-1'):
    return {'sub': sub, 'email': email, 'email_verified': verified, 'name': 'Иван Петров'}


def session(repo, token, role_id=None):
    return asyncio.run(AuthService(repo).session(token, SessionRequest(role_id=role_id)))


def test_known_user():
    known = user('a@example.com', 'kc-1')
    assert session(FakeUsers(known), claims('a@example.com')) is known


def test_new_user_needs_role():
    with pytest.raises(RegistrationRequiredError):
        session(FakeUsers(), claims())


def test_new_owner_created_with_name_from_token():
    repo = FakeUsers()
    created = session(repo, claims(), role_id=2)
    assert (created.keycloak_id, created.role_id, created.full_name) == ('kc-1', 2, 'Иван Петров')


def test_moderator_role_cannot_be_chosen():
    with pytest.raises(RoleNotAssignableError):
        session(FakeUsers(), claims(), role_id=4)


def test_old_account_linked_only_with_verified_email():
    old = user('old@example.com')
    with pytest.raises(AccountLinkRequiredError):
        session(FakeUsers(old), claims('old@example.com', verified=False))
    assert old.keycloak_id is None
    assert session(FakeUsers(old), claims('old@example.com', verified=True)) is old
    assert old.keycloak_id == 'kc-1'


def test_email_of_other_keycloak_account_is_refused():
    other = user('taken@example.com', 'kc-other')
    with pytest.raises(AccountLinkRequiredError):
        session(FakeUsers(other), claims('taken@example.com', verified=True))
