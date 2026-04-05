# Realtime Service

Сервис реального времени для платформы Migom. Доставляет события покупателям, менеджерам торговых точек и курьерам через WebSocket без необходимости polling.

## Цель

Когда пользователь создаёт заказ, статус заказа меняется или курьер движется - все заинтересованные стороны получают обновление мгновенно. Сервис является **read-only** наблюдателем: он не пишет в БД и не вызывает другие сервисы, только читает события из Kafka и раздаёт их подключённым клиентам.

## Архитектура

```
delivery_service
    │
    │  Kafka (order.created, order.status_updated,
    │          courier.assigned, courier.location_updated,
    │          courier.order_offer)
    ▼
realtime_service
    ├── kafka.Consumer   - читает топики, один reader на топик
    ├── hub.Hub          - маршрутизирует события по роли/ID
    │     ├── byUserID   - индекс клиентов по user_id
    │     └── byOutletID - индекс клиентов по outlet_id
    └── handler.WS       - HTTP → WebSocket upgrade, JWT-авторизация
```

## Подключение

```
ws://localhost/ws?token=<access_jwt>
```

Токен - стандартный access JWT, выданный `business_service`. Тип токена должен быть `access`. Передаётся как query-параметр, так как браузерный WebSocket API не поддерживает произвольные заголовки.

## Маршрутизация событий

| Kafka-топик | Получатели |
|---|---|
| `order.created` | менеджер/владелец точки (`outlet_id`) |
| `order.status_updated` | покупатель, менеджер точки, курьер |
| `courier.assigned` | покупатель, менеджер точки |
| `courier.location_updated` | покупатель активного заказа |
| `courier.order_offer` | конкретный курьер (`courier_user_id`) |

> `courier.order_offer` - push-оффер: система сама находит ближайшего свободного курьера и отправляет ему заказ через WebSocket. У курьера есть 30 секунд на ответ. Маршрутизация по полю `courier_user_id` в payload.
>
> Для заказов с `delivery_type=pickup` статус `assigned` не используется - цепочка: `new → assembling → ready_for_pickup → received`. Событие `courier.assigned` для самовывоза не публикуется.
>
> Для доставки финальный статус `received` устанавливается покупателем после того как курьер отметил `delivered`. Покупатель должен нажать "Подтвердить получение" (`POST /orders/{id}/confirm`).

Права определяются из JWT: поле `role` определяет тип пользователя, `outlet_id` (для роли `outlet_manager`) - к какой точке подписывать клиента.

## Формат сообщений

Все события приходят клиенту в одном формате:

```json
// order.status_updated
{
  "topic": "order.status_updated",
  "payload": {
    "order_id": 42,
    "status": "assembling",
    "customer_id": 1,
    "outlet_id": 3,
    "courier_id": null
  }
}

// courier.location_updated
{
  "topic": "courier.location_updated",
  "payload": {
    "courier_id": 7,
    "user_id": 12,
    "latitude": 55.751244,
    "longitude": 37.618423
  }
}

// courier.order_offer - предложение заказа курьеру
{
  "topic": "courier.order_offer",
  "payload": {
    "order_id": 42,
    "courier_id": 7,
    "courier_user_id": 12,
    "expires_in": 30
  }
}
```

## Конфигурация (.env)

| Переменная | Описание | По умолчанию |
|---|---|---|
| `PORT` | HTTP-порт сервиса | `8080` |
| `JWT_SECRET` | Секрет для валидации JWT (должен совпадать с `business_service`) | - |
| `KAFKA_BROKERS` | Адреса брокеров через запятую | `kafka:9092` |
| `KAFKA_GROUP_ID` | Consumer group ID | `realtime_service` |

## Эндпоинты

| Метод | Путь | Описание |
|---|---|---|
| `GET` | `/ws?token=` | WebSocket-соединение |
| `GET` | `/health` | Статус сервиса и метрики соединений |

```json
// GET /health
{"status":"ok","connections":12,"unique_users":10}
```

Через nginx:
- WebSocket: `ws://localhost/ws?token=<JWT>`
- Health: `http://localhost/realtime/health`

## Структура проекта

```
realtime_service/
├── cmd/
│   └── main.go                - точка входа, HTTP-сервер, graceful shutdown
├── internal/
│   ├── auth/
│   │   └── jwt.go             - валидация JWT (HS256)
│   ├── config/
│   │   └── config.go          - загрузка переменных окружения
│   ├── handler/
│   │   └── ws.go              - upgrade HTTP → WebSocket
│   ├── hub/
│   │   ├── hub.go             - менеджер соединений, маршрутизация событий
│   │   └── client.go          - WebSocket-клиент, ping/pong keepalive
│   └── kafka/
│       └── consumer.go        - Kafka consumer, один reader на топик
├── Dockerfile
└── .env.example
```
