Части репо указаны у задач. Команды Python - из папки сервиса, Go - из `backend/realtime_service`, docker compose - из `infra`.

## 1. business_service

- [x] 1.1 Настройки `KEYCLOAK_*`, клиент Keycloak (вход по паролю, обновление, выход, Admin API) и проверка токена по JWKS в `app/core`. Проверка: модульный тест - токен с верной подписью принимается, с чужим `aud`, истёкший и подписанный другим ключом отклоняются.
- [x] 1.2 Столбец `keycloak_id`, необязательный `password_hash`, миграция Alembic. Проверка: `alembic upgrade head` на базе docker compose.
- [x] 1.3 Вход, перенос при первом входе, обновление, выход, регистрация с привязкой существующей учётной записи, смена пароля, `get_current_user` по `keycloak_id`, `GET /auth/identity`. Проверка: сценарии specs через API на локальном стенде (Keycloak Goden и docker compose Мигома).

## 2. delivery_service

- [x] 2.1 Та же проверка токена, пользователь, роль и точка управляющего из базы. Проверка: заказ покупателя и действие управляющего через API на локальном стенде с токеном Keycloak; токен Goden - 401.

## 3. realtime_service

- [x] 3.1 Подключение WebSocket через `GET /auth/identity` business_service, настройки без `JWT_SECRET`. Проверка: `go test ./...`; на локальном стенде курьер подключается к `/ws` с токеном Keycloak, с испорченным токеном - 401.

## 4. Инфраструктура и документация

- [x] 4.1 `infra/docker-compose.yml` (доступ к Keycloak хоста), `.env.example` сервисов, README сервисов и `docs/goden-integration.md`. Проверка: стенд поднимается по README; упомянутые переменные есть в коде.
