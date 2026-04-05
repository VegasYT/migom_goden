import axios from 'axios';
import type { TokenResponse } from '@features/auth';

export const httpClient = axios.create({
	baseURL: import.meta.env.VITE_API_URL,
	headers: { 'Content-Type': 'application/json', 'ngrok-skip-browser-warning': '69420' },
});

// Lazy-import чтобы избежать circular dependency с features/auth
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let _getAuthState: (() => { accessToken: string | null; refreshToken: string | null; setTokens: (a: string, r: string) => void; logout: () => void }) | null = null;

export function _injectAuthStore(
	getter: () => { accessToken: string | null; refreshToken: string | null; setTokens: (a: string, r: string) => void; logout: () => void },
) {
	_getAuthState = getter;
}

// ─── Request interceptor ──────────────────────────────────────────────────────

httpClient.interceptors.request.use((config) => {
	const token = _getAuthState?.().accessToken ?? null;
	if (token) config.headers.Authorization = `Bearer ${token}`;
	if (config.data instanceof FormData) {
		delete config.headers['Content-Type'];
	}
	return config;
});

// ─── Token refresh logic ──────────────────────────────────────────────────────

let isRefreshing = false;
// Очередь промисов, ожидающих нового access-токена
let refreshQueue: ((token: string) => void)[] = [];

function processQueue(newToken: string) {
	refreshQueue.forEach((resolve) => resolve(newToken));
	refreshQueue = [];
}

// ─── Response interceptor ─────────────────────────────────────────────────────

httpClient.interceptors.response.use(
	(response) => response,
	async (error) => {
		const originalRequest = error.config as typeof error.config & { _retry?: boolean };

		if (error.response?.status !== 401 || originalRequest._retry) {
			return Promise.reject(error);
		}

		const authState = _getAuthState?.();
		if (!authState?.refreshToken) {
			authState?.logout();
			return Promise.reject(error);
		}

		// Если рефреш уже идёт - ставим запрос в очередь
		if (isRefreshing) {
			return new Promise((resolve, reject) => {
				refreshQueue.push((token) => {
					originalRequest.headers.Authorization = `Bearer ${token}`;
					resolve(httpClient(originalRequest));
				});
				// На случай если рефреш провалится
				setTimeout(() => reject(error), 10_000);
			});
		}

		originalRequest._retry = true;
		isRefreshing = true;

		try {
			// Используем чистый axios чтобы не попасть в свой же interceptor
			const { data } = await axios.post<TokenResponse>(
				`${import.meta.env.VITE_API_URL}/api/v1/auth/refresh`,
				{ refresh_token: authState.refreshToken },
			);

			authState.setTokens(data.access_token, data.refresh_token);
			processQueue(data.access_token);

			originalRequest.headers.Authorization = `Bearer ${data.access_token}`;
			return httpClient(originalRequest);
		} catch (refreshError) {
			refreshQueue = [];
			authState?.logout();
			return Promise.reject(refreshError);
		} finally {
			isRefreshing = false;
		}
	},
);
