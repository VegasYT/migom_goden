Части репо указаны у задач.

## 1. Сборка и настройки

- [x] 1.1 `frontend/owner_web`, `frontend/moderator_web`: Dockerfile, Caddyfile, `.dockerignore`, `packageManager`; сборка owner_web без ошибок типов. Проверка: `docker build` обоих кабинетов, страница и адрес SPA отвечают 200, в бандле адрес API сервера.
- [x] 1.2 `infra/`: `compose.prod.yaml`, `.env.example`, `.gitignore`, real IP в nginx. Проверка: `docker compose -f infra/compose.prod.yaml config` с тестовым `.env`.
- [x] 1.3 `backend/business_service`: миграция ролей, ссылка на фото со схемой. Проверка: миграция на базе с ролями ничего не меняет; pytest.

## 2. Выкладка

- [x] 2.1 `infra/deploy.sh`, `.github/workflows/deploy.yml`, `.gitattributes`. Проверка: выкладка на сервер скриптом.
- [x] 2.2 Сервер: секреты, первый запуск. Проверка: `https://migom.site/health`, кабинеты на `owner.` и `admin.` открываются, вход владельца, подключение к точке Goden и заказ через Goden на сервере.

## 3. Итог

- [x] 3.1 README в корне (выкладка), `docs/goden-integration.md` (раздел 5). Проверка: команды совпадают со скриптами.
