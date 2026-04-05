# Архитектура

Проект использует **Feature-based** архитектуру - упрощённый вариант FSD без жёстких правил публичного API между отдельными фичами, но с чёткой слоистой структурой.

## Слои

```
src/
├── app/        ← инициализация: роутер, провайдеры, глобальные стили
├── pages/      ← страницы (композиция features + layout)
├── features/   ← изолированные бизнес-фичи
└── shared/     ← переиспользуемая база: UI, API, утилиты, типы
```

### Правила импортов

| Слой       | Может импортировать из        |
| ---------- | ----------------------------- |
| `app`      | `pages`, `features`, `shared` |
| `pages`    | `features`, `shared`          |
| `features` | `shared`, другие `features`   |
| `shared`   | только внутри `shared`        |

> **Ключевое ограничение**: `app` не экспортируется в нижние слои. `shared` не импортирует из `features` или `pages`.

Path aliases настроены в `tsconfig.app.json`:

```
@app/*     →  src/app/*
@pages/*   →  src/pages/*
@features/* → src/features/*
@shared/*  →  src/shared/*
```

---

## `app/` - слой инициализации

```
src/app/
├── main.tsx          ← точка входа React, монтирование провайдеров
├── App.tsx           ← корневой компонент, инициализация роутера
├── router.ts         ← (планируется) createBrowserRouter
└── assets/
    └── index.css     ← глобальные стили
```

**Роутер** создаётся через `createBrowserRouter` (React Router **data API**):

- Не использует декларативный `<Routes>/<Route>` подход
- Не использует framework-mode (Remix-подобный)
- `loader` и `action` подключаются по необходимости к конкретным роутам
- Если роутер разрастается - разбивать на файлы `app/routes/auth.ts`, `app/routes/dashboard.ts` и т.д.

```ts
// app/router.ts - пример структуры
import { createBrowserRouter } from 'react-router';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <RootLayout />,
    children: [
      { index: true, element: <DashboardPage /> },
      {
        path: 'menu',
        element: <MenuPage />,
        loader: menuLoader,   // ← data API
      },
    ],
  },
  {
    path: '/auth',
    element: <AuthPage />,
    action: authAction,       // ← data API
  },
]);
```

---

## `pages/` - слой страниц

Страница - это **композиция** feature-компонентов и layout-элементов. Сама страница не содержит бизнес-логики.

```
src/pages/
├── DashboardPage/
│   └── index.tsx
├── MenuPage/
│   └── index.tsx
└── AuthPage/
    └── index.tsx
```

Страница экспортирует один default-компонент и, при необходимости, `loader`/`action` для роутера.

---

## `features/` - слой бизнес-фич

Каждая фича - это изолированный модуль по конкретной бизнес-задаче.

### Структура фичи

```
src/features/
└── auth/
    ├── ui/           ← React-компоненты
    │   ├── LoginForm.tsx
    │   └── RegisterForm.tsx
    ├── model/        ← Zustand-сторы, классы, бизнес-модели
    │   └── authStore.ts
    ├── api/          ← axios-запросы + TanStack Query хуки
    │   ├── authApi.ts
    │   └── useLogin.ts
    ├── types/        ← TypeScript-типы фичи
    │   └── index.ts
    ├── lib/          ← хуки, утилиты, константы фичи
    │   └── useAuthRedirect.ts
    └── index.ts      ← barrel: публичный API фичи (ОБЯЗАТЕЛЕН)
```

> **Barrel-файл обязателен** для каждой фичи. Внешние слои импортируют только из `index.ts`.

### Пример barrel-файла

```ts
// features/auth/index.ts
export { LoginForm, RegisterForm } from './ui';
export { useAuthStore } from './model/authStore';
export { useLogin } from './api/useLogin';
export type { AuthUser, LoginPayload } from './types';
```

### Список планируемых фич

| Фича             | Описание                           |
| ---------------- | ---------------------------------- |
| `auth`           | Регистрация, вход, сессия          |
| `organization`   | Создание и управление организацией |
| `menu`           | Создание меню, категорий, позиций  |
| `outlets`        | Торговые точки                     |
| `delivery-zones` | Зоны доставки                      |
| `orders`         | Просмотр и управление заказами     |

---

## `shared/` - переиспользуемая база

```
src/shared/
├── api/          ← axios instance, interceptors, базовые утилиты запросов
├── ui/           ← базовые и составные UI-компоненты (обёртки Chakra UI)
├── model/        ← глобальные Zustand-сторы (не привязанные к конкретной фиче)
├── lib/          ← хуки, утилиты, константы (theme.ts и др.)
└── types/        ← глобальные TypeScript-типы и интерфейсы
```

### `shared/api`

Содержит:

- `httpClient.ts` - axios instance с baseURL из env и default headers
- Interceptors: прокидывание токена, обработка 401, refresh

```ts
// shared/api/httpClient.ts - пример
import axios from 'axios';

export const httpClient = axios.create({
	baseURL: import.meta.env.VITE_API_URL,
});

httpClient.interceptors.request.use((config) => {
	const token = useAuthStore.getState().token;
	if (token) config.headers.Authorization = `Bearer ${token}`;
	return config;
});
```

### `shared/ui`

Компоненты двух типов:

1. **Base** - тонкие обёртки над MUI с кастомными дефолтами
2. **Composite** - составные компоненты из других `shared/ui` компонентов

### `shared/model`

Только **глобальные** сторы - данные, которые используются в нескольких несвязанных фичах. Фичо-специфичные сторы живут в `features/[feature]/model/`.

### `shared/lib`

- UI system (токены, семантические цвета)
- Хуки, не привязанные к фиче
- Общие утилиты (форматирование, валидаторы и т.д.)

### `shared/types`

Глобальные типы: базовые entity-интерфейсы, общие API-ответы, утилит-типы.
