## Why

Мигом выложен на `migom.site`, но мобильные приложения ходят на адрес ngrok, зашитый в код: с телефона прод недоступен. Ключ Яндекс MapKit лежит в коде открытого репозитория. Покупатель не видит курьера на карте: событие позиции курьера не называет покупателя, и realtime не знает, кому его отправить. Кроме того, курьер, чей заказ собирается или ждёт выдачи, считается свободным.

## What Changes

- Адрес API мобильных приложений задаётся при сборке (`--dart-define=API_URL=...`), по умолчанию `https://migom.site/api/v1`; адрес WebSocket выводится из него, как и раньше.
- Ключ MapKit курьерского приложения берётся при сборке из `android/local.properties` (`mapkit.apiKey`) или переменной `MAPKIT_API_KEY`, в коде его нет.
- Событие `courier.location_updated` несёт `customer_id` и `order_id` активного заказа курьера: realtime доставляет его покупателю этого заказа.
- Обновление позиции не стирает состояние курьера в Redis (активный заказ и выход на смену): иначе курьер мог закрыть смену с заказом на руках.
- Активный заказ курьера - заказ в статусах `assigned`, `assembling`, `ready_for_pickup` и `in_delivery`, а не только в первом и последнем.

Вне изменения:
- перевыпуск ключа MapKit: он уже в истории открытого репозитория, перевыпускает владелец ключа;
- сборка и публикация приложений в магазинах;
- вход в мобильных приложениях через браузер (этап 2 входа).

## Capabilities

### New Capabilities

- `courier-tracking`: позиция курьера у покупателя, активный заказ курьера.

### Modified Capabilities

Нет.

## Impact

- `backend/delivery_service`: `couriers/service.py`, `orders/repository.py`, тесты.
- `mobile/customer_app`, `mobile/courier_app`: `lib/core/api/api_client.dart`; courier_app - `android/app/build.gradle.kts`, `MainApplication.kt`.
- README мобильных приложений или корневой README: сборка с адресом API и ключом MapKit.
- `realtime_service`: не меняется, он уже маршрутизирует событие по `customer_id`.
