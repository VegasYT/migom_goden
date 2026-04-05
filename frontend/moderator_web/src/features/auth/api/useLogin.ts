import { useMutation } from '@tanstack/react-query';
import { useNavigate } from 'react-router';
import { toaster } from '@shared/ui/toaster';
import { useAuthStore } from '../model/authStore';
import { authApi } from './authApi';
import type { LoginDto } from '../types';

export function useLogin() {
	const navigate = useNavigate();
	const setAuth = useAuthStore((s) => s.setAuth);
	const setUser = useAuthStore((s) => s.setUser);

	return useMutation({
		mutationFn: (dto: LoginDto) => authApi.login(dto),
		onSuccess: async (data) => {
			// Устанавливаем токены сразу - interceptor их подхватит
			setAuth(data.access_token, data.refresh_token);

			try {
				const user = await authApi.getMe();
				setUser(user);
			} catch {
				// Не блокируем вход при ошибке загрузки профиля
			}

			toaster.success({ title: 'Добро пожаловать!' });
			void navigate('/');
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail = error.response?.data?.detail ?? 'Ошибка при входе';
			toaster.error({ title: detail });
		},
	});
}
