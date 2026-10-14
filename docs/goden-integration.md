# Интеграция Мигома с Goden

Что поменять в Мигоме и в Goden, чтобы Мигом входил через Keycloak Goden и брал у Goden наличие блюд и оформление заказов на кухню. Пути и строки указаны на коммит `6ce140a`, перед правкой сверяйтесь с кодом.

Goden - сервис учёта остатков, сроков годности и стоп-листа ресторана: репозиторий `C:\VS_code\Goden`, стенд https://goden.pro, Keycloak https://auth.goden.pro (realm `goden`), API https://goden.pro/api/v1, контракт `backend/api/openapi.yaml` в репозитории Goden.

## Решения

- Один realm `goden` на оба продукта: иначе владелец не войдёт в Goden и Мигом одной учётной записью. Покупатель Мигома сможет войти и в веб Goden и увидит там создание компании - это принято.
- Вход переводится в два этапа. Этап 1: учётные записи хранит Keycloak, клиенты Мигома не меняются. Этап 2: веб-клиенты входят перенаправлением на Keycloak (единый вход с Goden).
- Покупатели и курьеры Goden не видят: с Goden разговаривает backend Мигома от своего имени, сервисной учётной записью.
- Цены остаются в Мигоме, в Goden их нет. Goden отвечает за наличие по рецептурам и расход продуктов.

## 1. Вход через Keycloak, этап 1

Keycloak хранит учётные записи и выдаёт токены RS256. Адреса и ответы `/auth/*` у клиентов не меняются.

| Где | Сейчас | Что сделать |
|---|---|---|
| `backend/business_service/app/core/security.py` | выдача HS256 токенов общим секретом, bcrypt | выдачу токенов убрать; проверка токена RS256 по JWKS realm (python-jose уже стоит), проверка `iss` и `aud`; bcrypt оставить только для переноса пользователей |
| `backend/business_service/app/modules/auth/service.py:28` (`register`) | пишет пользователя в `users` | создать пользователя в Keycloak через Admin API (пароль, email, атрибуты), затем строку в `users` и вход |
| `auth/service.py:51` (`login`) | сверяет bcrypt | вход в Keycloak по паролю (token endpoint, `grant_type=password`); если пользователя в Keycloak нет, а пароль совпал с bcrypt в `users`, создать его в Keycloak с этим паролем (перенос при первом входе) |
| `auth/service.py:59` (`refresh`) | разбирает свой refresh-токен | `grant_type=refresh_token` в Keycloak |
| `auth/service.py:77` (`logout`) | ничего не делает | отзыв refresh-токена в Keycloak (`/protocol/openid-connect/logout`) |
| `auth/service.py:82` (`_issue_tokens`) | кладёт `role` и `outlet_id` в токен | роль, id Мигома и `outlet_id` хранить в атрибутах пользователя Keycloak, в токен их добавляют mapper'ы |
| `backend/business_service/app/core/dependencies.py:17` (`get_current_user`) | `sub` - id Мигома, проверка `type=access` | проверять токен Keycloak, пользователя искать по id из claim (см. ниже); `type` в токене Keycloak нет - проверять `typ=Bearer` |
| `backend/business_service/app/modules/users/models.py:20` (`User`) | `password_hash` обязателен | столбец `keycloak_id` (uuid, уникальный), `password_hash` сделать необязательным; миграция Alembic |
| `backend/business_service/app/modules/outlets/service.py:199` (`add_manager`) | назначает управляющего в БД | после назначения записать `outlet_id` в атрибут пользователя Keycloak, иначе токен будет нести старое |
| `backend/delivery_service/app/core/security.py`, `app/core/dependencies.py:22` | проверка HS256, `outlet_id` из токена | та же проверка RS256 по JWKS, что в business_service |
| `backend/realtime_service/internal/auth/jwt.go:34` (`Parse`) | HS256, `sub` - число, `type=access` | проверка RS256 по JWKS (например, `github.com/MicahParks/keyfunc` к уже стоящему `golang-jwt`), id пользователя из claim `migom_user_id`, роль и `outlet_id` - из своих claim |
| `backend/realtime_service/internal/config/config.go:18` | `JWT_SECRET` | `KEYCLOAK_ISSUER` (адрес realm) и ожидаемый `aud` |
| `.env.example` всех сервисов, `infra/docker-compose.yml` | `JWT_SECRET`, `JWT_ALGORITHM` | `KEYCLOAK_ISSUER`, `KEYCLOAK_AUDIENCE`, клиент и секрет backend для Admin API и входа по паролю |

Claim токена для Мигома (mapper'ы атрибутов пользователя в клиентском scope `migom`):

- `migom_user_id` - числовой `users.id`: события Kafka адресованы им, realtime сверяет их с токеном;
- `migom_role` - `customer`, `owner`, `courier`, `moderator`, `outlet_manager`;
- `outlet_id` - только у управляющего точкой.

Что добавить в realm Goden (`infra/keycloak/goden-realm.json` в репозитории Goden):

- клиент `migom-backend`: конфиденциальный, вход по паролю (`directAccessGrantsEnabled`), сервисная учётная запись с правами `manage-users` и `view-users` на `realm-management`;
- клиент `migom-web` (этап 2): публичный, PKCE, адреса `owner_web` и `moderator_web`;
- клиентский scope `migom` с mapper'ами атрибутов и audience `migom`;
- тестовые пользователи из README Мигома (`admin@migom.ru`, `owner@migom.ru`, `user@migom.ru`, `courier@migom.ru`) с атрибутами.

## 2. Вход через Keycloak, этап 2 (единый вход в вебе)

| Где | Что сделать |
|---|---|
| `frontend/owner_web/src/features/auth/api/authApi.ts` | вход перенаправлением на Keycloak с PKCE вместо формы; образец - `frontend/src/shared/auth` в Goden |
| `frontend/owner_web/src/shared/api/httpClient.ts:45` | очередь обновления токена заменить обновлением из keycloak-js |
| `frontend/moderator_web/src/features/auth/api/authApi.ts`, `src/shared/api/httpClient.ts` | то же |
| `mobile/customer_app/lib/features/auth/data/auth_service.dart`, `mobile/courier_app/lib/features/auth/data/auth_service.dart` | можно оставить на этапе 1 (вход по паролю через backend); вход через браузер - `flutter_appauth`, отдельная задача |

## 3. Наличие блюд и заказы через Goden

Сопоставление сущностей (миграция Alembic в business_service):

- `outlets.goden_point_id` (uuid) - точка Goden; `companies.goden_company_id` - компания Goden;
- `catalog_items.goden_dish_id` (uuid) - блюдо Goden. Позиции, которые продаются как есть (напитки), в Goden должны быть блюдом с рецептурой из одного продукта, иначе они в стоп-листе с причиной "нет рецептуры".

| Где | Сейчас | Что сделать |
|---|---|---|
| `backend/business_service/app/modules/outlets/service.py:101` (`get_outlet_menu`, кеш `outlet_menu:{outlet_id}`) | доступность из `outlet_item_availability` | у точки с `goden_point_id` брать доступность и число порций из `GET /points/{pointId}/menu` Goden; кеш на 15-30 секунд; Goden недоступен - показывать меню без отметок наличия или из кеша |
| `outlets/service.py:142` (`list_items_availability`), `:167` (`set_item_availability`) | ручная доступность | у точки Goden ручную доступность убрать или оставить как "выключить блюдо" (`PUT /points/{pointId}/dishes/{dishId}` Goden) |
| `backend/delivery_service/app/modules/orders/service.py:80` (`create_order`) | заказ создаётся без проверки наличия | до создания и публикации `order.created` (`:151`) - `POST /points/{pointId}/orders` в Goden с `Idempotency-Key` = ключ заказа Мигома; `rejected` - ответ покупателю с недостающими продуктами (`shortages[].product.name`), заказ не создаётся; `accepted` - создать заказ как сейчас |
| `orders/service.py:192` (`customer_cancel`), `:415` (`owner_cancel`), `:484` (`admin_cancel`) | только статус `cancelled` | вернуть продукты в Goden отменой заказа - такой операции в Goden пока нет (см. раздел 4) |
| новый клиент Goden в delivery_service и business_service | исходящих HTTP-вызовов нет | клиент с токеном сервисной учётной записи (`client_credentials`), тайм-ауты, ключи идемпотентности, разбор ошибок `application/problem+json` |

Порядок при создании заказа: если Goden принял заказ, а сохранение в Мигоме упало, повтор с тем же ключом вернёт тот же ответ Goden и продукты не спишутся дважды. Если заказ в Мигоме так и не создан, принятый заказ в Goden нужно отменить (раздел 4).

## 4. Что нужно в Goden

- Отмена заказа с возвратом остатков в партии: команда, событие, операция API. Сейчас заказ в Goden отменить нельзя.
- Права интеграции на точке: клиент с ролью вроде `migom.integration` получает на точке права `kitchen.view` (меню) и `orders.accept` (заказы) только там, где владелец включил Мигом. Образец - права генератора (`generator.run` и `generator.Service.PointPermissions` в Goden).
- Клиенты и scope Мигома в `infra/keycloak/goden-realm.json` (раздел 1).
- Необязательно: сигналы стоп-листа для сброса кеша меню Мигома (поток `GET /points/{pointId}/events`, категория `stop-list`).

## 5. Попутно замеченное

- `backend/realtime_service/internal/hub/hub.go:179`: событие `courier.location_updated` маршрутизируется по `customer_id`, а в полезной нагрузке (`delivery_service`, `couriers/service.py:103`) его нет - позиция курьера, судя по коду, не доходит до покупателя.
- `mobile/courier_app/android/app/src/main/kotlin/com/migom/courier_app/MainApplication.kt`: ключ Яндекс MapKit записан в коде открытым текстом.
- `mobile/customer_app/lib/core/api/api_client.dart:4`, `mobile/courier_app/lib/core/api/api_client.dart:4`: адрес API зашит (ngrok); вынести в `--dart-define`.
- Тестов почти нет: только `backend/realtime_service/internal/auth/jwt_test.go` и `internal/hub/hub_test.go`. Перед переделкой входа стоит покрыть `get_current_user` и вход тестами.

## Открытые вопросы

- Где работает Мигом на стенде и какой Keycloak он видит: `auth.goden.pro` или локальный `localhost:8180`.
- Регистрация с выбором роли (`role_id` в `/auth/register`): оставить выбор как есть или выдавать владельцев и курьеров только модератором.
- Нужен ли Мигому сигнал от Goden об изменении меню (сброс кеша) или хватит короткого кеша.
