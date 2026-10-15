# deployment Specification

## Purpose
TBD - created by archiving change server-deployment. Update Purpose after archive.

## Requirements

### Requirement: Мигом на сервере Goden
Мигом SHALL работать на сервере Goden под своим доменом: API и WebSocket для мобильных приложений и фото товаров на основном домене, кабинет владельца на `owner.`, кабинет модератора на `admin.`, всё по HTTPS. Мигом SHALL пользоваться Kafka, Keycloak и API Goden на этом же сервере и SHALL NOT запускать свой Kafka.

#### Scenario: Кабинет владельца
- **WHEN** владелец открывает `https://owner.migom.site` и входит
- **THEN** кабинет работает с API `https://migom.site`, подключение к точке Goden и заказы идут через Goden этого сервера

#### Scenario: Фото товара
- **WHEN** владелец загружает фото товара
- **THEN** ссылка на фото открывается по `https://migom.site/migom-media/...`

### Requirement: Выкладка Мигома
Коммит в `master` SHALL выкладываться на сервер после успешных тестов backend. Выкладка SHALL сохранять данные и секреты сервера и SHALL ждать окончания выкладки Goden на том же сервере.

#### Scenario: Новый коммит
- **WHEN** в `master` попадает коммит и тесты проходят
- **THEN** сервер собирает и перезапускает изменившиеся сервисы, пользователи и заказы сохраняются

### Requirement: Справочник ролей
Роли пользователей (покупатель, владелец, курьер, модератор, менеджер точки) SHALL заводиться при миграции базы, без ручного SQL.

#### Scenario: Пустая база
- **WHEN** Мигом впервые запускается на пустой базе
- **THEN** регистрация покупателя и владельца работает
