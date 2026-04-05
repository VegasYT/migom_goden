import { useMutation } from '@tanstack/react-query';
import { useNavigate } from 'react-router';
import { toaster } from '@shared/ui/toaster';
import { useAuthStore } from '../model/authStore';
import { authApi } from './authApi';
import type { RegisterDto } from '../types';

export function useRegister() {
	const navigate = useNavigate();
	const setAuth = useAuthStore((s) => s.setAuth);
	const setUser = useAuthStore((s) => s.setUser);

	return useMutation({
		mutationFn: (dto: RegisterDto) => authApi.register(dto),
		onSuccess: async (data) => {
			setAuth(data.access_token, data.refresh_token);

			try {
				const user = await authApi.getMe();
				setUser(user);
			} catch {
				// Не блокируем вход при ошибке загрузки профиля
			}

			toaster.success({ title: 'Аккаунт создан!', description: 'Добро пожаловать в Migom' });
			void navigate('/');
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail = error.response?.data?.detail ?? 'Ошибка при регистрации';
			toaster.error({ title: detail });
		},
	});
}
