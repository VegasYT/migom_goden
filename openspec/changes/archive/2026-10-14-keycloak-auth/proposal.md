## Why

Мигом переводит вход на Keycloak Goden (realm `goden`, план - `docs/goden-integration.md`, раздел 1): учётные записи хранит Keycloak, чтобы потом владелец входил в Мигом и Goden одной учётной записью. Это этап 1: клиенты Мигома (веб и мобильные приложения) не меняются.

## What Changes

- `/auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/register` в business_service сохраняют адреса и ответы, но вход и обновление идут в Keycloak (клиент `migom-backend`), выход отзывает переданный refresh-токен, регистрация заводит пользователя в Keycloak через Admin API.
- Существующие пользователи переносятся при первом входе: пароль сверяется с bcrypt в базе Мигома и становится паролем в Keycloak.
- Регистрация с почтой, которая уже есть в Keycloak (например, у пользователя Goden), привязывает эту учётную запись, если пароль от неё верный.
- Смена пароля (`/users/me/change-password`) меняет пароль в Keycloak.
- business_service и delivery_service проверяют токен Keycloak (RS256, ключи JWKS realm, `iss`, `aud` `migom-api`) и берут пользователя, роль и точку управляющего из базы Мигома по id пользователя в Keycloak.
- realtime_service не разбирает токен сам: при подключении WebSocket спрашивает у business_service, кто владелец токена (`GET /api/v1/auth/identity`).
- В `users` - столбец `keycloak_id`, `password_hash` становится необязательным.
- Настройки: `KEYCLOAK_*` вместо `JWT_SECRET` во всех сервисах.

Вне изменения:
- вход в веб перенаправлением на Keycloak (этап 2);
- роли в Keycloak: роль и точка управляющего остаются в базе Мигома;
- блокировка пользователя в Keycloak: заблокированного по-прежнему отклоняет Мигом по `is_active`;
- наличие блюд и заказы через Goden.

## Capabilities

### New Capabilities

- `auth`: вход, регистрация и проверка токенов через Keycloak Goden.

### Modified Capabilities

Нет.

## Impact

- `backend/business_service`: `app/core/security.py`, `app/core/dependencies.py`, `app/config.py`, модули `auth` и `users`, миграция Alembic, `requirements.txt`.
- `backend/delivery_service`: `app/core/security.py`, `app/core/dependencies.py`, `app/config.py`, `requirements.txt`.
- `backend/realtime_service`: `internal/auth`, `internal/config`, `cmd/main.go`.
- `infra/docker-compose.yml`, `.env.example` сервисов.
- Клиенты (веб и мобильные): API не меняется.
- Goden: клиенты `migom-api` и `migom-backend` в realm - change `migom-keycloak-clients` в репозитории Goden.
