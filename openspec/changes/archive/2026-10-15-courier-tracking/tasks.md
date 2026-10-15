Части репо указаны у задач.

## 1. Backend

- [x] 1.1 `backend/delivery_service`: активный заказ курьера во всех статусах от `assigned` до `in_delivery` (`get_active_by_courier`). Проверка: pytest.
- [x] 1.2 `backend/delivery_service`: `update_location` сохраняет состояние курьера в Redis и передаёт в событии `customer_id` и `order_id` активного заказа. Проверка: pytest на подменённых репозиториях и Redis; на проде позиция курьера приходит покупателю по WebSocket.

## 2. Мобильные приложения

- [x] 2.1 `mobile/customer_app`, `mobile/courier_app`: `API_URL` через `--dart-define`, по умолчанию `https://migom.site/api/v1`. Проверка: `flutter analyze`.
- [x] 2.2 `mobile/courier_app`: ключ MapKit из `local.properties` или `MAPKIT_API_KEY` через `BuildConfig`. Проверка: `flutter build apk --debug` собирается, в коде ключа нет.

## 3. Итог

- [x] 3.1 README: сборка приложений с адресом API и ключом MapKit; `docs/goden-integration.md` (раздел 6). Проверка: команды совпадают с кодом.
