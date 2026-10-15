import { useEffect } from 'react';
import { useNavigate } from 'react-router';
import { useAuthStore } from '../model/authStore';
import { ROLE_OUTLET_MANAGER } from '../types';

/**
 * Менеджеров торговых точек перенаправляет на /outlet-manager.
 * Используется на страницах владельца; без входа кабинет не открывается (SessionGate).
 */
export function useAuthGuard() {
	const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
	const user = useAuthStore((s) => s.user);
	const navigate = useNavigate();

	useEffect(() => {
		if (user?.role?.id === ROLE_OUTLET_MANAGER) {
			void navigate('/outlet-manager', { replace: true });
		}
	}, [user, navigate]);

	return { isAuthenticated };
}

/** Guard для страницы менеджера точки: остальных перенаправляет на /. */
export function useOutletManagerGuard() {
	const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
	const user = useAuthStore((s) => s.user);
	const navigate = useNavigate();

	useEffect(() => {
		if (user && user.role?.id !== ROLE_OUTLET_MANAGER) {
			void navigate('/', { replace: true });
		}
	}, [user, navigate]);

	return { isAuthenticated };
}
