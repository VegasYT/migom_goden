import { useEffect } from 'react';
import { useNavigate } from 'react-router';
import { useAuthStore } from '../model/authStore';
import { ROLE_OUTLET_MANAGER } from '../types';

/**
 * Перенаправляет неаутентифицированных пользователей на /auth.
 * Менеджеров торговых точек перенаправляет на /outlet-manager.
 * Используется на защищённых страницах owner-а.
 */
export function useAuthGuard() {
	const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
	const user = useAuthStore((s) => s.user);
	const navigate = useNavigate();

	useEffect(() => {
		if (!isAuthenticated) {
			void navigate('/auth', { replace: true });
		} else if (user?.role?.id === ROLE_OUTLET_MANAGER) {
			void navigate('/outlet-manager', { replace: true });
		}
	}, [isAuthenticated, user, navigate]);

	return { isAuthenticated };
}

/**
 * Guard для страницы менеджера точки.
 * Перенаправляет на /auth если не авторизован, на / если не менеджер.
 */
export function useOutletManagerGuard() {
	const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
	const user = useAuthStore((s) => s.user);
	const navigate = useNavigate();

	useEffect(() => {
		if (!isAuthenticated) {
			void navigate('/auth', { replace: true });
		} else if (user && user.role?.id !== ROLE_OUTLET_MANAGER) {
			void navigate('/', { replace: true });
		}
	}, [isAuthenticated, user, navigate]);

	return { isAuthenticated };
}

/**
 * Перенаправляет аутентифицированных пользователей на / или /outlet-manager.
 * Используется на странице авторизации.
 */
export function useGuestGuard() {
	const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
	const user = useAuthStore((s) => s.user);
	const navigate = useNavigate();

	useEffect(() => {
		if (isAuthenticated) {
			if (user?.role?.id === ROLE_OUTLET_MANAGER) {
				void navigate('/outlet-manager', { replace: true });
			} else {
				void navigate('/', { replace: true });
			}
		}
	}, [isAuthenticated, user, navigate]);
}
