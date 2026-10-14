Части репо указаны у задач. Команды backend - из папки сервиса.

## 1. Клиенты Goden

- [x] 1.1 `backend/business_service`: в `app/core/goden.py` клиент сервисной учётной записи - токен `client_credentials` с кешем, `GET /migom/points` с кешем 30 секунд, `GET /points/{pointId}/menu`; настройки `GODEN_CLIENT_ID`, `GODEN_CLIENT_SECRET`, `.env.example`. Проверка: pytest на подменённом транспорте.
- [x] 1.2 `backend/delivery_service`: `app/core/goden.py` - тот же токен и сверка пары, `POST /points/{pointId}/orders` с `Idempotency-Key`, отмена заказа; настройки `GODEN_API_URL`, `GODEN_CLIENT_ID`, `GODEN_CLIENT_SECRET`, `.env.example`. Проверка: pytest на подменённом транспорте (принят, отклонён с продуктами, недоступен, 401 с новым токеном).

## 2. Меню

- [x] 2.1 `backend/business_service`: меню подключённого заведения (`get_outlet_menu`) по наличию Goden, кеш 20 секунд, пустое меню без пары, ручная доступность при недоступном Goden. Проверка: сквозная проверка - блюдо без продуктов и товар без связи пропадают из меню, после отключения в Goden меню пустое.

## 3. Заказы

- [x] 3.1 `backend/delivery_service`: миграция `orders.goden_point_id`, `orders.goden_order_id`; оформление через Goden с 409 при нехватке и товаре без связи, 503 при недоступности, компенсация. Проверка: сквозная проверка - заказ списывает продукты в Goden, нехватка даёт 409 с продуктами и сохраняет корзину.
- [x] 3.2 `backend/delivery_service`: возврат продуктов в Goden при отмене в статусах `new` и `assigned` (покупатель, заведение, модератор), без обращения к Goden позже, отмена в Мигоме при недоступном Goden. Проверка: сквозная проверка - остатки в Goden вернулись после отмены нового заказа и не вернулись после отмены в `assembling`.

## 4. Итог

- [x] 4.1 README business_service и корневой README (у delivery_service своего README нет), `docs/goden-integration.md`. Проверка: описанные настройки и поведение есть в коде.
