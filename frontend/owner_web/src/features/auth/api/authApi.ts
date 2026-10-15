import { httpClient } from '@shared/api/httpClient';
import type { AuthUser } from '../types';

export const authApi = {
	/** Пользователь Мигома по токену Keycloak; role_id заводит нового пользователя с этой ролью. */
	session: (body: { role_id?: number; phone?: string } = {}) =>
		httpClient.post<AuthUser>('/api/v1/auth/session', body).then((r) => r.data),
};
