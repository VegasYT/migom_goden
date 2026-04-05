import { useEffect } from 'react';
import { useNavigate } from 'react-router';
import { useAuthStore } from '../model/authStore';

/**
 * Перенаправляет неаутентифицированных пользователей на /auth.
 * Используется на защищённых страницах.
 */
export function useAuthGuard() {
	const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
	const navigate = useNavigate();

	useEffect(() => {
		if (!isAuthenticated) {
			void navigate('/auth', { replace: true });
		}
	}, [isAuthenticated, navigate]);

	return { isAuthenticated };
}

/**
 * Перенаправляет аутентифицированных пользователей на /.
 * Используется на странице авторизации.
 */
export function useGuestGuard() {
	const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
	const navigate = useNavigate();

	useEffect(() => {
		if (isAuthenticated) {
			void navigate('/', { replace: true });
		}
	}, [isAuthenticated, navigate]);
}
