# Соглашения и паттерны

## Именование

| Тип | Стиль | Пример |
|-----|-------|--------|
| Компоненты (файлы и функции) | PascalCase | `LoginForm.tsx`, `MenuItemCard.tsx` |
| Хуки | camelCase с `use` | `useMenuItems.ts`, `useAuthStore.ts` |
| Сторы Zustand | camelCase с `use` + `Store` | `useAuthStore`, `useUiStore` |
| API-модули | camelCase с `Api` | `menuApi`, `authApi` |
| Query Key-фабрики | camelCase с `Keys` | `menuKeys`, `authKeys` |
| Типы / интерфейсы | PascalCase | `MenuItem`, `CreateMenuItemDto` |
| Папки фич и страниц | camelCase | `auth/`, `deliveryZones/` |
| Barrel-файлы | `index.ts` | обязательно для каждой фичи |

---

## Структура файлов компонента

Для простых компонентов - один файл `.tsx`.  
Для сложных - папка с `index.tsx` как точкой входа:

```
features/menu/ui/
├── MenuItemCard/
│   ├── index.tsx          ← экспортирует компонент
│   └── MenuItemCard.tsx   ← реализация (опционально)
└── MenuList.tsx
```

---

## Barrel-файлы

**Обязательны** для каждой фичи. Внешние слои импортируют **только** из barrel-файла.

```ts
// features/menu/index.ts
export { MenuList, MenuItemCard, CreateMenuItemForm } from './ui';
export { useMenuItems, useCreateMenuItem } from './api';
export { useMenuStore } from './model/menuStore';
export type { MenuItem, MenuCategory } from './types';
```

Внутри фичи можно импортировать напрямую без barrel:
```ts
// features/menu/ui/MenuList.tsx
import { useMenuItems } from '../api/useMenuItems';  // ✅ внутри фичи - ок
```

Из другой фичи - только через barrel:
```ts
// features/orders/ui/OrderMenuItem.tsx
import { type MenuItem } from '@features/menu';  // ✅ через barrel
import { useMenuItems } from '@features/menu/api/useMenuItems'; // ❌ нарушение
```

---

## Паттерн API-хука

Каждый запрос - отдельный файл. Query key factory - рядом с хуком использования.

```ts
// features/menu/api/menuApi.ts
import { httpClient } from '@shared/api/httpClient';
import type { MenuItem } from '../types';

export const menuApi = {
  getItems: (categoryId?: string) =>
    httpClient
      .get<MenuItem[]>('/menu/items', { params: { categoryId } })
      .then((r) => r.data),

  deleteItem: (id: string) =>
    httpClient.delete(`/menu/items/${id}`),
};
```

```ts
// features/menu/api/useMenuItems.ts
import { useQuery } from '@tanstack/react-query';
import { menuApi } from './menuApi';

export const menuKeys = {
  all: ['menu'] as const,
  items: (categoryId?: string) => [...menuKeys.all, 'items', categoryId] as const,
};

export function useMenuItems(categoryId?: string) {
  return useQuery({
    queryKey: menuKeys.items(categoryId),
    queryFn: () => menuApi.getItems(categoryId),
  });
}
```

---

## Паттерн Zustand-стора

```ts
// features/auth/model/authStore.ts
import { create } from 'zustand';

// 1. Интерфейс стора
interface AuthStore {
  token: string | null;
  user: AuthUser | null;
  setAuth: (token: string, user: AuthUser) => void;
  logout: () => void;
}

// 2. Создание стора
export const useAuthStore = create<AuthStore>((set) => ({
  token: null,
  user: null,
  setAuth: (token, user) => set({ token, user }),
  logout: () => set({ token: null, user: null }),
}));
```

**Получение стейта вне React** (например, в interceptors):
```ts
useAuthStore.getState().token
useAuthStore.getState().logout()
```

---

## Паттерн формы

```ts
// features/organization/ui/CreateOrganizationForm.tsx
import { useForm } from '@tanstack/react-form';
import { z } from 'zod';

// 1. Zod-схема - выносим отдельно (в lib/ или types/)
const schema = z.object({
  name: z.string().min(2, 'Минимум 2 символа'),
  inn: z.string().length(10, 'ИНН должен содержать 10 цифр'),
});

type FormValues = z.infer<typeof schema>;

export function CreateOrganizationForm() {
  const createOrg = useCreateOrganization(); // useMutation
  
  const form = useForm({
    defaultValues: { name: '', inn: '' } satisfies FormValues,
    validators: { onChange: schema },
    onSubmit: async ({ value }) => {
      try {
        await createOrg.mutateAsync(value);
      } catch (err) {
        // серверные ошибки - прокидываем в форму
      }
    },
  });

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit(); }}>
      <form.Field name="name">
        {(field) => (
          <>
            <input
              value={field.state.value}
              onChange={(e) => field.handleChange(e.target.value)}
              onBlur={field.handleBlur}
            />
            {field.state.meta.errors.length > 0 && (
              <span>{field.state.meta.errors[0]}</span>
            )}
          </>
        )}
      </form.Field>
    </form>
  );
}
```

---

## Работа с темой MUI

Использовать **токены темы** вместо захардкоженных цветов:

```tsx
// ✅ Правильно - работает в light/dark
<Box sx={{ bgcolor: 'background.paper', color: 'text.primary', borderColor: 'divider' }}>

// ❌ Неправильно - не адаптируется к теме
<Box sx={{ bgcolor: 'white', color: '#4A5568' }}>
```

Доступные токены палитры: `background.default`, `background.paper`, `text.primary`, `text.secondary`, `primary.main`, `divider`, `error.main`.

---

## TypeScript

- **Строгий режим** включён (`"strict": true`)
- Использовать `type` для импортов типов: `import type { ... }`
- `satisfies` используется там, где нужен вывод типов + проверка формы
- DTO-типы именовать с суффиксом: `CreateMenuItemDto`, `UpdateOutletDto`
- Response-типы именовать как entity: `MenuItem`, `Organization`

---

## Добавление новой фичи - чеклист

1. Создать папку `src/features/[feature-name]/`
2. Добавить структуру: `ui/`, `model/`, `api/`, `types/`, `lib/`
3. Создать `index.ts` с barrel-экспортами
4. Создать API-модуль в `api/[feature]Api.ts`
5. Создать query хуки в `api/use[Action].ts` с query key factory
6. Создать Zustand-стор в `model/[feature]Store.ts` (если нужен клиентский стейт)
7. Определить TypeScript типы в `types/index.ts`
8. Реализовать UI в `ui/`
9. Подключить страницу в `pages/`
10. Добавить роут в `app/router.ts`

---

## Структура env-переменных

```env
# .env.local (не коммитить)
VITE_API_URL=http://localhost:8080

# .env.example (коммитить, без значений)
VITE_API_URL=
```

Обращение:

```ts
const API_URL = import.meta.env.VITE_API_URL;
```

---

## Что НЕ делать

| ❌ Нарушение | ✅ Правильно |
|-------------|-------------|
| Импорт из `app/` в `pages/` | `app` не экспортирует в нижние слои |
| Прямой импорт из внутренностей чужой фичи | Только через barrel `index.ts` |
| Хранить серверные данные в Zustand | Серверные данные - TanStack Query |
| Добавлять `useMemo`/`useCallback` руками | React Compiler делает это автоматически |
| Захардкодить цвета в MUI компонентах | Использовать токены темы через `sx` |
| Создавать несколько axios инстансов | Один `httpClient` из `shared/api` |
