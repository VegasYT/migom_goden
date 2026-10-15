import axios from 'axios';
import { accessToken, keycloak } from '@shared/auth/keycloak';

export const httpClient = axios.create({
	baseURL: import.meta.env.VITE_API_URL,
	headers: {
		'Content-Type': 'application/json',
		'ngrok-skip-browser-warning': '69420',
	},
});

httpClient.interceptors.request.use(async (config) => {
	const token = await accessToken();
	if (token) config.headers.Authorization = `Bearer ${token}`;
	if (config.data instanceof FormData) {
		delete config.headers['Content-Type'];
	}
	return config;
});

// токен отозван или сессию закрыли в Keycloak: заново на страницу входа
httpClient.interceptors.response.use(
	(response) => response,
	async (error) => {
		if (error.response?.status === 401) await keycloak.login();
		return Promise.reject(error);
	},
);
