import { httpClient } from '@shared/api/httpClient';
import type { AuthUser } from '../types';

export const authApi = {
	/** Пользователь Мигома по токену Keycloak. Кабинет модератора новых пользователей не заводит. */
	session: () => httpClient.post<AuthUser>('/api/v1/auth/session', {}).then((r) => r.data),
};
