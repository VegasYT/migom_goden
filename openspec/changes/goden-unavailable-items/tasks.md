Части репо: `backend/delivery_service` (команды из `backend/delivery_service`: `pytest`), `mobile/customer_app` (из `mobile/customer_app`: `dart analyze lib`, `flutter build apk --release`).

## 1. delivery_service

- [x] 1.1 `goden.menu(point_id)` со всеми страницами. Проверка: тест в `tests/test_goden.py` на MockTransport - две страницы склеиваются.
- [x] 1.2 Чистая функция: товары корзины, которые нельзя заказать, по порциям заказа и меню; `_order_in_goden` при отказе (нехватка, 4xx кроме 403) читает меню и отвечает `UnavailableItemsError`, при недоступном меню - прежней ошибкой. Проверка: модульный тест функции - нет в меню, `available: false`, порций меньше, всё хватает; тест текста ошибки.

## 2. Приложение покупателя

- [x] 2.1 Окно "Ресторан отменил заказ" с причиной на главном экране. Проверка: `dart analyze lib` без ошибок и предупреждений, `flutter build apk --release` собирается.
