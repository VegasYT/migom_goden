import { useEffect } from 'react';
import { useNavigate } from 'react-router';
import { useOrganizationStore } from '../model/organizationStore';

/**
 * Перенаправляет на /organization/new если у пользователя нет организации.
 * Используется на защищённых страницах после авторизации.
 */
export function useOrganizationGuard() {
	const companyId = useOrganizationStore((s) => s.companyId);
	const navigate = useNavigate();

	useEffect(() => {
		if (companyId === null) {
			void navigate('/organization/new', { replace: true });
		}
	}, [companyId, navigate]);

	return { companyId };
}

/**
 * Перенаправляет на / если у пользователя уже есть организация.
 * Используется на странице создания организации.
 */
export function useNoOrganizationGuard() {
	const companyId = useOrganizationStore((s) => s.companyId);
	const navigate = useNavigate();

	useEffect(() => {
		if (companyId !== null) {
			void navigate('/', { replace: true });
		}
	}, [companyId, navigate]);
}
