Части репо: `backend/delivery_service` (команды из `backend/delivery_service`: `pytest`), `mobile/customer_app` (команды из `mobile/customer_app`: `flutter analyze`), `docs/`.

## 1. delivery_service

- [x] 1.1 Функция `goden.order(point_id, order_id)` - чтение заказа Goden. Проверка: тест в `tests/test_goden.py` на MockTransport - ответ разбирается, 404 даёт `GodenRefusedError`, 5xx - `GodenUnavailableError`.
- [x] 1.2 Столбец `orders.cancel_reason` (миграция Alembic), поле `cancel_reason` в `OrderResponse`. Проверка: `alembic upgrade head` и `alembic downgrade -1` на базе разработки, `pytest`.
- [x] 1.3 Решение "отменить ли и с какой причиной" чистой функцией по статусу Мигома и заказу Goden; `OrderService.cancel_from_goden` (повторная проверка статуса, причина, сброс курьера, `order.status_updated`, без обращения к Goden). Проверка: модульный тест функции - отмена с комментарием и без, `delivered`/`received`/`cancelled` не трогаются, заказ `accepted` в Goden не отменяется.
- [x] 1.4 Фоновая задача `goden_cancel_worker` в `lifespan`: проход раз в 15 с, недоступный Goden прерывает проход, 403/404 пропускают заказ. Проверка: модульный тест прохода с подменой чтения - недоступность и отказ не роняют задачу; запуск сервиса без ошибок в журнале.

## 2. Приложение покупателя

- [x] 2.1 `cancel_reason` в `ApiOrderModel`, причина у отменённого заказа в деталях прошлого заказа (в карточке только статус). Проверка: `dart analyze lib` без ошибок и предупреждений (`flutter analyze` в этом окружении не запускается).

## 3. Документация

- [x] 3.1 `docs/goden-integration.md`: отмена заказа в Goden и опрос. Проверка: упомянутые пути есть в коде.
