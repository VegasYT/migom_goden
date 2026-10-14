Части репо указаны у задач. Команды backend - из папки `backend/business_service`.

## 1. Backend: данные и клиент Goden

- [x] 1.1 `backend/business_service`: миграция Alembic - `outlets.goden_point_id` (uuid, частичный уникальный индекс), `catalog_items.goden_dish_id` (uuid, частичный уникальный индекс с `company_id`); поля в моделях и ответах заведения и товара. Проверка: `alembic upgrade head` и `downgrade -1` на локальной базе.
- [x] 1.2 `backend/business_service`: `app/core/goden.py` - запросы в API Goden с токеном пользователя (`GET /me`, `PUT /points/{pointId}/migom`, `GET /points/{pointId}/menu` со всеми страницами), ошибки 403, 404, 409 и недоступность; настройка `GODEN_API_URL`, `.env.example`. Проверка: pytest на подменённом транспорте httpx.

## 2. Backend: операции

- [x] 2.1 `backend/business_service`: модуль `app/modules/goden` - `GET /goden/points`, `PUT /outlets/{outlet_id}/goden` (подключение, смена и отключение), доступ владельца компании. Проверка: сквозная проверка с локальным Goden - подключение своей точки, 403 на чужую, 409 на занятую, отключение; в Goden `GET /points/{pointId}/migom` показывает номер заведения.
- [x] 2.2 `backend/business_service`: `GET /outlets/{outlet_id}/goden/dishes`, `goden_dish_id` в создании и изменении товара, `POST /outlets/{outlet_id}/goden/link-by-name`. Проверка: сквозная проверка - список блюд, товар из блюда, связь по названию, 409 на второй товар и на неподключённое заведение.

## 3. owner_web

- [x] 3.1 `frontend/owner_web`: блок "Goden" в настройках заведения (выбор своей точки, отключение) и окно "Блюда Goden" (связать с товаром, создать товар, связать по названию). Проверка: `vite build` и eslint на изменённых файлах (`tsc -b` падал и до change на старых ошибках в `features/menu`, `outlets/api`, `shared/ui/tooltip.tsx`); в браузере подключение точки и связь блюд проходят.

## 4. Итог

- [x] 4.1 README business_service и owner_web, `docs/goden-integration.md`. Проверка: описанные настройки и операции есть в коде.
