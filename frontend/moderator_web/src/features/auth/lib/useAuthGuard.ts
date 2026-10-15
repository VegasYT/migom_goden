import { useAuthStore } from '../model/authStore';

/** Признак входа для страниц: без входа модератора кабинет не открывается (SessionGate). */
export function useAuthGuard() {
	const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
	return { isAuthenticated };
}
