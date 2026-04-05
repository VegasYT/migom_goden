import { useMutation } from '@tanstack/react-query';
import { useNavigate } from 'react-router';
import { toaster } from '@shared/ui/toaster';
import { useAuthStore } from '../model/authStore';
import { authApi } from './authApi';
import { organizationApi, useOrganizationStore } from '@features/organization';
import { ROLE_OUTLET_MANAGER } from '../types';
import type { LoginDto } from '../types';

export function useLogin() {
	const navigate = useNavigate();
	const setAuth = useAuthStore((s) => s.setAuth);
	const setUser = useAuthStore((s) => s.setUser);
	const setCompanyId = useOrganizationStore((s) => s.setCompanyId);

	return useMutation({
		mutationFn: (dto: LoginDto) => authApi.login(dto),
		onSuccess: async (data) => {
			// Устанавливаем токены сразу - interceptor их подхватит
			setAuth(data.access_token, data.refresh_token);

			try {
				const user = await authApi.getMe();
				setUser(user);

				// Менеджер точки - не загружаем компании, перенаправляем
				if (user.role?.id === ROLE_OUTLET_MANAGER) {
					toaster.success({ title: 'Добро пожаловать!' });
					void navigate('/outlet-manager', { replace: true });
					return;
				}

				// Owner - загружаем компании
				try {
					const companies = await organizationApi.getMy();
					if (companies.length > 0) {
						setCompanyId(companies[0].id);
					}
				} catch {
					// Не блокируем вход
				}
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
