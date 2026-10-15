# Интеграция Мигома с Goden

Что поменять в Мигоме и в Goden, чтобы Мигом входил через Keycloak Goden и брал у Goden наличие блюд и оформление заказов на кухню. Пути и строки указаны на коммит `6ce140a`, перед правкой сверяйтесь с кодом.

Goden - сервис учёта остатков, сроков годности и стоп-листа ресторана: репозиторий `C:\VS_code\Goden`, стенд https://goden.pro, Keycloak https://auth.goden.pro (realm `goden`), API https://goden.pro/api/v1, контракт `backend/api/openapi.yaml` в репозитории Goden.

## Решения

- Один realm `goden` на оба продукта: иначе владелец не войдёт в Goden и Мигом одной учётной записью. Покупатель Мигома сможет войти и в веб Goden и увидит там создание компании - это принято.
- Вход переводится в два этапа. Этап 1: учётные записи хранит Keycloak, клиенты Мигома не меняются. Этап 2: веб-клиенты входят перенаправлением на Keycloak (единый вход с Goden).
- Покупатели и курьеры Goden не видят: с Goden разговаривает backend Мигома от своего имени, сервисной учётной записью.
- Цены остаются в Мигоме, в Goden их нет. Goden отвечает за наличие по рецептурам и расход продуктов.

## 1. Вход через Keycloak, этап 1 - сделано

OpenSpec change `keycloak-auth` в Мигоме, клиенты realm - change `migom-keycloak-clients` в Goden (ветка `migom-keycloak-clients` от `backend`).

- `/auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/register` прежние по адресам и ответам, внутри - Keycloak (`app/core/keycloak.py` business_service, клиент `migom-backend`).
- Существующие пользователи переносятся при первом входе со своим паролем (сверка с bcrypt), регистрация с почтой, которая уже есть в realm, привязывает учётную запись при верном пароле от неё. Смена пароля - в Keycloak.
- business_service и delivery_service проверяют токен по JWKS realm (`app/core/security.py`), роль, блокировку и точку управляющего берут из базы по `users.keycloak_id`.
- realtime_service токен не разбирает: спрашивает `GET /api/v1/auth/identity` у business_service при подключении.
- Атрибутов пользователя и mapper'ов в Keycloak нет: от первоначального плана с claim `migom_user_id`, `migom_role`, `outlet_id` отказались, чтобы не синхронизировать роль и точку с Keycloak.
- Настройки сервисов: `KEYCLOAK_REALM_URL`, `KEYCLOAK_ISSUER`, `KEYCLOAK_AUDIENCE`, у business_service ещё `KEYCLOAK_CLIENT_ID` и `KEYCLOAK_CLIENT_SECRET`; у realtime - `BUSINESS_URL`. `JWT_SECRET` больше нигде не нужен.
- Проверено: модульные тесты проверки токена (`backend/business_service/tests`), сквозная проверка сценариев спеки на локальном стенде.

## 2. Вход через Keycloak, этап 2 (единый вход в вебе)

Сделано (change `web-sso`, в Goden - `migom-web-client`): кабинеты входят перенаправлением на Keycloak (клиент `migom-web`, PKCE, тема Goden), формы входа и регистрации удалены, новый пользователь регистрируется на странице Keycloak и при первом входе выбирает роль (`POST /auth/session`). Старая учётная запись Мигома связывается со входом только по подтверждённой почте. Мобильные приложения остаются на входе по паролю. Ниже - исходный план.

| Где | Что сделать |
|---|---|
| `frontend/owner_web/src/features/auth/api/authApi.ts` | вход перенаправлением на Keycloak с PKCE вместо формы; образец - `frontend/src/shared/auth` в Goden |
| `frontend/owner_web/src/shared/api/httpClient.ts:45` | очередь обновления токена заменить обновлением из keycloak-js |
| `frontend/moderator_web/src/features/auth/api/authApi.ts`, `src/shared/api/httpClient.ts` | то же |
| `mobile/customer_app/lib/features/auth/data/auth_service.dart`, `mobile/courier_app/lib/features/auth/data/auth_service.dart` | можно оставить на этапе 1 (вход по паролю через backend); вход через браузер - `flutter_appauth`, отдельная задача |

## 3. Наличие блюд и заказы через Goden

Сопоставление сущностей - сделано (change `goden-binding`):

- `outlets.goden_point_id` (uuid) - точка Goden, `catalog_items.goden_dish_id` (uuid) - блюдо Goden. Заведение и точка остаются разными сущностями: у каждой системы свои данные, Мигом работает и с ресторанами без Goden;
- владелец заведения и владелец точки - один пользователь общего Keycloak. Мигом показывает ему его точки Goden и подключает выбранную от его имени: токены `migom-backend` несут `aud` `goden-api` (change `migom-user-tokens` в Goden), Мигом вызывает `PUT /points/{pointId}/migom` с номером заведения и сохраняет `goden_point_id`. Подтверждение двустороннее: одной операцией и в Goden, и в Мигоме, и только для точки, которой пользователь владеет;
- товары связываются с блюдами точки в окне "Goden" owner_web: по названию, вручную или созданием товара из блюда. Позиции, которые продаются как есть (напитки), в Goden должны быть блюдом с рецептурой из одного продукта, иначе они в стоп-листе с причиной "нет рецептуры";
- при обращениях сервисной учётной записи `migom-integration` (заказы, наличие) Мигом сверяет пару `(goden_point_id, outlets.id)` с `GET /migom/points`: владелец точки может отключить Мигом в Goden в любой момент.

Наличие и заказы - сделано (change `goden-orders`): меню подключённого заведения по наличию Goden, заказ сначала в Goden (нехватка - 409 с продуктами, недоступность - 503, компенсация при сбое Мигома), возврат продуктов при отмене в статусах `new` и `assigned`, при недоступном Goden отмена только в Мигоме. Товары без связи с блюдом у подключённого заведения не продаются. Ниже - исходный план по местам в коде.

Отмена заказа сотрудником точки Goden - сделано (change `goden-cancel-sync`): Goden Мигому не сообщает, поэтому delivery_service раз в 15 секунд читает в Goden свои незавершённые заказы (`GET /points/{pointId}/orders/{orderId}`, `backend/delivery_service/app/core/goden_cancel_worker.py`). Заказ, отменённый в Goden, отменяется в Мигоме в любом статусе, кроме `delivered`, `received` и `cancelled`, с причиной `cancel_reason`: комментарий сотрудника или "Отменён рестораном". Обратно в Goden Мигом не обращается: продукты Goden вернул сам. Недоступный Goden прерывает проход, отмена дойдёт следующим; заказ, который Goden больше не отдаёт (403, 404), пропускается.

| Где | Сейчас | Что сделать |
|---|---|---|
| `backend/business_service/app/modules/outlets/service.py:101` (`get_outlet_menu`, кеш `outlet_menu:{outlet_id}`) | доступность из `outlet_item_availability` | у точки с `goden_point_id` брать доступность и число порций из `GET /points/{pointId}/menu` Goden; кеш на 15-30 секунд; Goden недоступен - показывать меню без отметок наличия или из кеша |
| `outlets/service.py:142` (`list_items_availability`), `:167` (`set_item_availability`) | ручная доступность | у точки Goden ручную доступность убрать или оставить как "выключить блюдо" (`PUT /points/{pointId}/dishes/{dishId}` Goden) |
| `backend/delivery_service/app/modules/orders/service.py:80` (`create_order`) | заказ создаётся без проверки наличия | до создания и публикации `order.created` (`:151`) - `POST /points/{pointId}/orders` в Goden с `Idempotency-Key` = ключ заказа Мигома; `rejected` - ответ покупателю с недостающими продуктами (`shortages[].product.name`), заказ не создаётся; `accepted` - создать заказ как сейчас |
| `orders/service.py:192` (`customer_cancel`), `:415` (`owner_cancel`), `:484` (`admin_cancel`) | только статус `cancelled` | вернуть продукты в Goden (`POST /points/{pointId}/orders/{orderId}/cancel`), **только пока заказ не начали готовить**: статусы `new` и `assigned`. Goden не знает, готовит ли кухня, и вернёт продукты при любом вызове; если отменить в Goden заказ в `assembling` и дальше, склад покажет продукты, которых нет, и меню предложит блюда, которые нельзя приготовить. Позже отмена в Мигоме меняет только его статус |
| новый клиент Goden в delivery_service и business_service | исходящих HTTP-вызовов нет | клиент с токеном сервисной учётной записи (`client_credentials`), тайм-ауты, ключи идемпотентности, разбор ошибок `application/problem+json` |

Порядок при создании заказа: если Goden принял заказ, а сохранение в Мигоме упало, повтор с тем же ключом вернёт тот же ответ Goden и продукты не спишутся дважды. Если заказ в Мигоме так и не создан, принятый заказ в Goden нужно отменить (раздел 4).

## 4. Что нужно в Goden

- Отмена заказа с возвратом остатков в партии: команда, событие, операция API - сделано (change `order-cancellation` в Goden).
- Права интеграции на точке: клиент `migom-integration` с ролью `migom.integration` получает на точке права `point.view`, `kitchen.view`, `orders.accept`, `orders.view` только там, где владелец подключил заведение Мигома (change `migom-access` в Goden). Отменить Мигом может только заказы, которые оформил сам: заказ официанта Goden вернёт 403.
- Клиенты `migom-api` и `migom-backend` в `infra/keycloak/goden-realm.json` - сделано (ветка `migom-keycloak-clients`); на сервере их заводит `keycloak-config` (change `migom-keycloak-server`); токены `migom-backend` принимает API Goden (change `migom-user-tokens`); клиент `migom-web` для этапа 2 - нет.
- Отмена заказа сотрудником с комментарием, право `orders.cancel` (у Мигома на подключённой точке - для своих заказов), `placed_by`, `cancelled_by` и `cancel_comment` в заказе - change `order-cancel-by-staff` в Goden.
- Необязательно: сигналы стоп-листа для сброса кеша меню Мигома (поток `GET /points/{pointId}/events`, категория `stop-list`).

## 5. Выкладка на сервер Goden (migom.site)

Сделано (change `server-deployment`, в Goden - `migom-site-proxy`): Мигом в сети Goden, Kafka общая, свои PostgreSQL с PostGIS, Redis и MinIO, адреса `migom.site`, `owner.` и `admin.` через Caddy Goden, выкладка `infra/deploy.sh` и GitHub Actions, порядок первого запуска - README в корне. Ниже - исходный план.

Мигом разворачивается на том же сервере, что и Goden (`84.54.59.138`, 4 ГБ памяти, 2 ядра), под доменом `migom.site`. По порядку:

1. **Перед выкладкой расширить swap до 4 ГБ** - сделано (4051 МБ). При выкладках Goden свободной памяти оставалось 200-400 МБ, swap был занят больше чем наполовину; Мигом добавит ещё PostgreSQL, Redis, Kafka, MinIO, три сервиса и nginx. Команды выполняет пользователь в своём терминале на сервере (нужен `sudo`).
2. Решить, какие сервисы Мигома делить с Goden: отдельный Kafka - сотни мегабайт; PostgreSQL Goden без PostGIS, а Мигому PostGIS нужен. Если памяти после swap всё равно мало - сервер побольше.
3. Порт 80 на сервере занят прокси Goden (Caddy): nginx Мигома наружу не публикуется, `migom.site` подключается через Caddy Goden.
4. Клиенты Мигома в Keycloak сервера: файл realm на сервере применяется только при первом создании тома, поэтому `migom-api` и `migom-backend` заводит `infra/keycloak/configure.sh` Goden, секрет - `MIGOM_BACKEND_SECRET` в `infra/.env` Goden.
5. Секреты Мигома (`JWT_SECRET` больше не нужен; пароли PostgreSQL, MinIO, секрет `migom-backend`) - в `.env` на сервере, не в репозитории.

## 6. Попутно замеченное

Позиция курьера, ключ MapKit и адрес API мобильных приложений исправлены (change `courier-tracking`); там же активный заказ курьера стал включать статусы сборки и ожидания выдачи.

- `backend/realtime_service/internal/hub/hub.go:179`: событие `courier.location_updated` маршрутизируется по `customer_id`, а в полезной нагрузке (`delivery_service`, `couriers/service.py:103`) его нет - позиция курьера, судя по коду, не доходит до покупателя.
- `mobile/courier_app/android/app/src/main/kotlin/com/migom/courier_app/MainApplication.kt`: ключ Яндекс MapKit записан в коде открытым текстом.
- `mobile/customer_app/lib/core/api/api_client.dart:4`, `mobile/courier_app/lib/core/api/api_client.dart:4`: адрес API зашит (ngrok); вынести в `--dart-define`.
- Тестов почти нет: только `backend/realtime_service/internal/auth/jwt_test.go` и `internal/hub/hub_test.go`. Перед переделкой входа стоит покрыть `get_current_user` и вход тестами.

## Открытые вопросы

- Где работает Мигом на стенде и какой Keycloak он видит: `auth.goden.pro` или локальный `localhost:8180`.
- Регистрация с выбором роли (`role_id` в `/auth/register`): оставить выбор как есть или выдавать владельцев и курьеров только модератором.
- Нужен ли Мигому сигнал от Goden об изменении меню (сброс кеша) или хватит короткого кеша.
