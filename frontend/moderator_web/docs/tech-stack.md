# Стек технологий

## Обзор

| Категория | Инструмент | Версия |
|-----------|-----------|--------|
| UI-фреймворк | React | ^19.2 |
| Язык | TypeScript | ~5.9 |
| Сборщик | Vite | ^8.0 |
| UI-библиотека | Material UI (MUI) | ^7.3 |
| Роутинг | React Router | ^7.14 |
| Стейт-менеджер | Zustand | ^5.0 |
| Запросы | Axios + TanStack Query | ^1.14 / ^5.96 |
| Формы | TanStack Form + Zod | ^1.28 / ^4.3 |
| Иконки | @mui/icons-material | ^7.3 |
| Оптимизатор | React Compiler (Babel) | ^1.0 |

---

## React Router v7 - Data API

Использується **data подход** (не declarative, не framework-mode).

### Ключевые концепции

```ts
import { createBrowserRouter, RouterProvider } from 'react-router';

// Роутер - в app/
const router = createBrowserRouter([...]);

// В main.tsx или App.tsx
<RouterProvider router={router} />
```

### Loader (предзагрузка данных)

```ts
// pages/MenuPage/index.tsx
import type { LoaderFunction } from 'react-router';
import { useLoaderData } from 'react-router';

export const loader: LoaderFunction = async () => {
  const data = await menuApi.getMenu();
  return data;
};

export default function MenuPage() {
  const menu = useLoaderData<typeof loader>();
  return <MenuList items={menu} />;
}
```

### Action (мутации формы)

```ts
import type { ActionFunction } from 'react-router';

export const action: ActionFunction = async ({ request }) => {
  const formData = await request.formData();
  // обработка POST/PUT/DELETE
  return redirect('/menu');
};
```

> **Важно**: Loader/action применяются **по необходимости**, не принудительно на каждом роуте. Для большинства случаев используется TanStack Query.

---

## TanStack Query v5 - Серверный стейт

Используется для всего, что связано с **серверными данными**: получение, кэширование, инвалидация.

### Запрос (useQuery)

```ts
// features/menu/api/useMenuItems.ts
import { useQuery } from '@tanstack/react-query';
import { menuApi } from './menuApi';

export const menuKeys = {
  all: ['menu'] as const,
  items: () => [...menuKeys.all, 'items'] as const,
};

export function useMenuItems() {
  return useQuery({
    queryKey: menuKeys.items(),
    queryFn: menuApi.getItems,
  });
}
```

### Мутация (useMutation)

```ts
// features/menu/api/useCreateMenuItem.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';

export function useCreateMenuItem() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: menuApi.createItem,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: menuKeys.items() });
    },
  });
}
```

---

## Axios - HTTP-клиент

Единый инстанс в `shared/api/httpClient.ts`.

```ts
import axios from 'axios';

export const httpClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: { 'Content-Type': 'application/json' },
});

// Request interceptor - добавление токена
httpClient.interceptors.request.use((config) => {
  const token = /* из zustand store */ '';
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Response interceptor - обработка ошибок / refresh
httpClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // refresh token logic
    }
    return Promise.reject(error);
  },
);
```

### API-модули в фичах

```ts
// features/menu/api/menuApi.ts
import { httpClient } from '@shared/api/httpClient';
import type { MenuItem, CreateMenuItemDto } from '../types';

export const menuApi = {
  getItems: () =>
    httpClient.get<MenuItem[]>('/menu/items').then((r) => r.data),
  
  createItem: (dto: CreateMenuItemDto) =>
    httpClient.post<MenuItem>('/menu/items', dto).then((r) => r.data),
};
```

---

## Zustand v5 - Клиентский стейт

Хранит **только клиентский стейт**: UI-состояние, данные сессии, что не является серверными данными.

### Стор фичи

```ts
// features/auth/model/authStore.ts
import { create } from 'zustand';

interface AuthStore {
  token: string | null;
  setToken: (token: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthStore>((set) => ({
  token: null,
  setToken: (token) => set({ token }),
  logout: () => set({ token: null }),
}));
```

### Глобальный стор (shared/model)

```ts
// shared/model/uiStore.ts
import { create } from 'zustand';

interface UiStore {
  sidebarOpen: boolean;
  toggleSidebar: () => void;
}

export const useUiStore = create<UiStore>((set) => ({
  sidebarOpen: true,
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
}));
```

> **Правило**: Серверные данные (списки, entities) - в TanStack Query. Клиентское состояние (авторизация, UI) - в Zustand.

---

## TanStack Form v1 + Zod v4 - Формы

```ts
// features/auth/ui/LoginForm.tsx
import { useForm } from '@tanstack/react-form';
import { z } from 'zod';

const loginSchema = z.object({
  email: z.string().email('Некорректный email'),
  password: z.string().min(8, 'Минимум 8 символов'),
});

type LoginForm = z.infer<typeof loginSchema>;

export function LoginForm() {
  const form = useForm({
    defaultValues: { email: '', password: '' } satisfies LoginForm,
    validators: {
      onChange: loginSchema,     // ← Zod схема напрямую
    },
    onSubmit: async ({ value }) => {
      // value типизирован как LoginForm
      await login(value);
    },
  });

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit(); }}>
      <form.Field name="email">
        {(field) => (
          <input
            value={field.state.value}
            onChange={(e) => field.handleChange(e.target.value)}
          />
        )}
      </form.Field>
    </form>
  );
}
```

### Серверные ошибки в форме

```ts
onSubmit: async ({ value }) => {
  try {
    await login(value);
  } catch (err) {
    // прокидываем серверную ошибку в поле
    form.setFieldMeta('email', (meta) => ({
      ...meta,
      errors: ['Неверный email или пароль'],
    }));
  }
},
```

---

## Material UI v7 - UI-библиотека

Использует **MUI v7** с кастомной темой через `createTheme`.

### Тема

Тема определена в `shared/lib/theme.ts`. Две темы: `lightTheme` и `darkTheme`.

**Цвета палитры:**

| Токен MUI | Light | Dark |
|-----------|-------|------|
| `background.default` | `#EEF4F5` | `#0F1117` |
| `background.paper` | `#FFFFFF` | `#1A1D27` |
| `text.primary` | `#4A5568` | `#E2E8F0` |
| `text.secondary` | `#8896A7` | `#8896A7` |
| `primary.main` | `#4ADE80` | `#34D399` |
| `divider` | `#E2E8F0` | `#2A2D3A` |
| `error.main` | `#EF4444` | `#EF4444` |

### ColorMode

Управляется собственным контекстом в `shared/ui/color-mode.tsx` (хранит выбор в `localStorage`):

```ts
import { useColorMode, useColorModeValue, ColorModeButton } from '@shared/ui/color-mode';

const { colorMode, toggleColorMode } = useColorMode();
const bg = useColorModeValue('#fff', '#000');
```

### Toaster

Реализован через MUI `Snackbar` + `Alert` в `shared/ui/toaster.tsx`:

```ts
import { toaster } from '@shared/ui/toaster';

toaster.success({ title: 'Сохранено!' });
toaster.error({ title: 'Ошибка', description: 'Что-то пошло не так' });
```

---

## React Compiler

Проект использует **React Compiler** (babel-plugin-react-compiler) для автоматической мемоизации. 

> Не нужно вручную писать `useMemo`, `useCallback`, `React.memo` - компилятор делает это автоматически. Добавляй их только если компилятор явно не справляется или есть специфические требования.

---

## Переменные окружения

```env
VITE_API_URL=https://api.migom.ru   # базовый URL бэкенда
```

Все переменные должны начинаться с `VITE_` для доступа через `import.meta.env`.
