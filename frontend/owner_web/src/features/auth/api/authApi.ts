import { httpClient } from '@shared/api/httpClient';
import type { AuthUser, LoginDto, RegisterDto, TokenResponse } from '../types';

export const authApi = {
	login: (dto: LoginDto) =>
		httpClient.post<TokenResponse>('/api/v1/auth/login', dto).then((r) => r.data),

	register: (dto: RegisterDto) =>
		httpClient.post<TokenResponse>('/api/v1/auth/register', dto).then((r) => r.data),

	refresh: (refresh_token: string) =>
		httpClient
			.post<TokenResponse>('/api/v1/auth/refresh', { refresh_token })
			.then((r) => r.data),

	logout: () => httpClient.post('/api/v1/auth/logout'),

	getMe: () =>
		httpClient.get<AuthUser>('/api/v1/users/me').then((r) => r.data),
};
