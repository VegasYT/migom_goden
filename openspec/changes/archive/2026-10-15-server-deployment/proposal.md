## Why

Связку Мигома с Goden можно показать только локально: Мигом не выложен. Его нужно развернуть на сервере Goden (`84.54.59.138`) под доменом `migom.site`, рядом с Goden и без второго экземпляра того, что у Goden уже есть.

## What Changes

- `infra/compose.prod.yaml`: Мигом на сервере в сети Goden `goden-prod_default`. Kafka - общая с Goden, Keycloak и API Goden - по внутренним адресам. Свои PostgreSQL с PostGIS, Redis и MinIO - только в сети Мигома. Наружу Мигом открывает Caddy Goden: `migom.site` (API, WebSocket, фото), `owner.migom.site` (кабинет владельца), `admin.migom.site` (кабинет модератора).
- Образы кабинетов `owner_web` и `moderator_web`: сборка Vite и раздача статики. Адрес API вшивается при сборке.
- `infra/deploy.sh` и GitHub Actions: пуш в `master` прогоняет тесты и выкладывает Мигом на сервер, как у Goden. Выкладки Goden и Мигома идут по очереди.
- Секреты сервера - `infra/.env` по `infra/.env.example`.
- Справочник ролей заводит миграция business_service: без него не работает регистрация.
- Ссылка на фото может нести свою схему (`MINIO_PUBLIC_ENDPOINT=https://migom.site`): браузер видит https, а сервис ходит в MinIO по http.
- nginx берёт адрес клиента из `X-Forwarded-For` от прокси: иначе ограничение частоты запросов делилось бы на всех.
- Сборка owner_web снова проходит: удалён неиспользуемый код категорий, исправлены две ошибки типов.

Правка в Goden - адреса Мигома в Caddy и очередь выкладок (change `migom-site-proxy`).

Вне изменения:
- мобильные приложения: адрес API в них по-прежнему задаётся в коде;
- единый вход в кабинетах через Keycloak (этап 2);
- резервные копии базы и MinIO.

## Capabilities

### New Capabilities

- `deployment`: Мигом на сервере Goden.

### Modified Capabilities

Нет.

## Impact

- `infra/`: `compose.prod.yaml`, `.env.example`, `.gitignore`, `deploy.sh`, `nginx/nginx.conf`.
- `frontend/owner_web`, `frontend/moderator_web`: `Dockerfile`, `Caddyfile`, `.dockerignore`, `packageManager` в `package.json`; owner_web - удалён код категорий, правки типов.
- `backend/business_service`: миграция ролей, ссылка на фото (`app/core/storage.py`).
- `.github/workflows/deploy.yml`, `.gitattributes`, README в корне, `docs/goden-integration.md`.
