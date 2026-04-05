# Закомментированный / заглушённый функционал

Этот файл документирует функционал, который в UI присутствует, но работает на мок-данных
из-за отсутствия соответствующих эндпоинтов в backend API.

---

## 1. Статистика курьера (вкладка «Статистика»)

**Файл:** `lib/features/courier/presentation/providers/stats_provider.dart`

**Что закомментировано / замоковано:**

| Поле UI | Откуда сейчас | Нужный эндпоинт |
|---------|--------------|-----------------|
| Заработок за период (сегодня/неделя/месяц) | `CourierMockData.periodStats` | Нет эндпоинта |
| Количество выполненных заказов за период | `CourierMockData.periodStats` | Нет эндпоинта |
| Средняя длительность доставки (мин) | `CourierMockData.periodStats` | Нет эндпоинта |
| Средняя сумма заказа | `CourierMockData.periodStats` | Нет эндпоинта |
| Пройденное расстояние за период | `CourierMockData.periodStats` | Нет эндпоинта |
| График заработка по дням недели | `CourierMockData.weeklyEarnings` | Нет эндпоинта |

**Что нужно от backend:** эндпоинт `GET /couriers/me/stats?period=today|week|month`
или аналогичный, возвращающий агрегированные данные по доставленным заказам.

---

## 2. История заказов курьера (вкладка «Заказы»)

**Файл:** `lib/features/courier/presentation/providers/order_history_provider.dart`

**Что закомментировано / замоковано:**

Вкладка «Заказы» показывает пустой список. Мок-данные из `OrderHistoryMockData` убраны.

**Причина:** В delivery_service нет эндпоинта для получения истории доставленных заказов
курьера. Доступны только:
- `GET /courier/orders/available` - заказы, доступные для принятия (новые в зоне)
- `GET /courier/orders/active` - текущий активный заказ

**Что нужно от backend:** `GET /courier/orders/history` или аналогичный, возвращающий
заказы курьера со статусами `delivered` / `received`, с пагинацией.

---

## 3. Данные последней смены на главной (виджет LastShiftSummary)

**Файл:** `lib/features/courier/presentation/widgets/home/last_shift_summary.dart`

**Что закомментировано / замоковано:**

Виджет «Последняя смена» показывает мок-данные: заработок, количество заказов,
пройденное расстояние, время активности.

**Причина:** API `GET /shifts/me/history` возвращает только `started_at`, `ended_at`,
`is_active`. Данные о заработке и заказах за смену не включены.

**Что нужно от backend:** расширить `ShiftResponse` полями `orders_completed`,
`earned`, `distance_km`.

---

## 4. Профиль курьера - totalDeliveries, totalDistanceKm

**Файл:** `lib/features/courier/presentation/providers/courier_profile_provider.dart`

**Что закомментировано / замоковано:**

Поля `totalDeliveries` и `totalDistanceKm` в `CourierProfileModel` всегда равны `0`,
так как API (`/couriers/me`) этих полей не возвращает.

**Что нужно от backend:** добавить агрегированные поля в `CourierResponse` или
предоставить отдельный эндпоинт статистики (см. п. 1).

---

## 5. Детали входящего заказа при WS-оффере

**Файл:** `lib/features/courier/presentation/providers/incoming_order_provider.dart`

**Что частично работает:**

При получении `courier.order_offer` через WebSocket приходит только:
```json
{ "order_id": 42, "courier_id": 7, "courier_user_id": 12, "expires_in": 30 }
```

Название ресторана, адрес точки, детали товаров - НЕ включены в payload.
Делается попытка загрузить данные через `GET /courier/orders/active`,
но этот эндпоинт возвращает заказ только после принятия (`accept`).

**Что нужно от backend:** включить в payload `courier.order_offer` поля
`outlet_address`, `outlet_name`, `customer_address`, `items`, `total_price`.
Либо добавить эндпоинт `GET /courier/orders/{id}/offer-details`.

---

## 6. Геозона доставки (delivery_zone_provider)

**Файл:** `lib/features/courier/presentation/providers/delivery_zone_provider.dart`

**Статус:** Радиус и центр зоны сохраняются локально в провайдере.
Обновление на сервер через `PATCH /couriers/me` (`radius_km`, `zone_latitude`,
`zone_longitude`) реализовано в `CourierApiService.updateProfile()`.

Загрузка текущей зоны с сервера при старте - реализована через `GET /couriers/me`
в `CourierProfileNotifier.build()`.

Нет функционала сравнения локальной зоны с серверной - при рестарте приложения
зона берётся из API.
