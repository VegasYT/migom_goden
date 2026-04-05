import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router';
import { toaster } from '@shared/ui/toaster';
import { useOrganizationStore } from '../model/organizationStore';
import { organizationApi } from './organizationApi';
import { organizationKeys } from './useOrganization';
import { myCompaniesKeys } from './useMyCompanies';
import type { CreateOrganizationDto } from '../types';

export function useCreateOrganization() {
	const navigate = useNavigate();
	const setCompanyId = useOrganizationStore((s) => s.setCompanyId);
	const queryClient = useQueryClient();

	return useMutation({
		mutationFn: (dto: CreateOrganizationDto) => organizationApi.create(dto),
		onSuccess: (data) => {
			setCompanyId(data.id);
			queryClient.setQueryData(organizationKeys.detail(data.id), data);
			void queryClient.invalidateQueries({ queryKey: myCompaniesKeys.all });
			toaster.success({ title: 'Организация создана!' });
			void navigate('/');
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail = error.response?.data?.detail ?? 'Ошибка при создании организации';
			toaster.error({ title: detail });
		},
	});
}
