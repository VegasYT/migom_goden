import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { organizationApi } from './organizationApi';
import { organizationKeys } from './useOrganization';
import { myCompaniesKeys } from './useMyCompanies';
import type { UpdateOrganizationDto } from '../types';

export function useUpdateOrganization() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ id, dto }: { id: number; dto: UpdateOrganizationDto }) =>
			organizationApi.update(id, dto),
		onSuccess: (_, { id }) => {
			void queryClient.invalidateQueries({ queryKey: organizationKeys.detail(id) });
			void queryClient.invalidateQueries({ queryKey: myCompaniesKeys.all });
			toaster.success({ title: 'Настройки компании сохранены' });
		},
		onError: () => toaster.error({ title: 'Не удалось сохранить изменения' }),
	});
}
