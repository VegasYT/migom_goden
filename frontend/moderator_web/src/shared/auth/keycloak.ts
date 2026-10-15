import Keycloak from 'keycloak-js';

/** Единый вход через Keycloak Goden: клиент кабинетов Мигома migom-web. */
export const keycloak = new Keycloak({
	url: import.meta.env.VITE_KEYCLOAK_URL ?? 'http://localhost:8180',
	realm: import.meta.env.VITE_KEYCLOAK_REALM ?? 'goden',
	clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID ?? 'migom-web',
});

/** Вход до запуска приложения: без сессии Keycloak уводит на свою страницу входа. */
export function startSession() {
	return keycloak.init({ onLoad: 'login-required', pkceMethod: 'S256', checkLoginIframe: false });
}

/** Действующий access token: продлевается заранее, а если сессия Keycloak кончилась, начинается вход заново. */
export async function accessToken(): Promise<string | undefined> {
	try {
		await keycloak.updateToken(30);
	} catch {
		await keycloak.login();
	}
	return keycloak.token;
}

/** Выход из Keycloak с возвратом в кабинет, который снова попросит войти. */
export function logout() {
	return keycloak.logout({ redirectUri: window.location.origin });
}
