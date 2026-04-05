import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { organizationApi } from './organizationApi';
import { organizationKeys } from './useOrganization';
import { myCompaniesKeys } from './useMyCompanies';

export function useDeleteOrganization() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: (id: number) => organizationApi.delete(id),
		onSuccess: (_, id) => {
			queryClient.removeQueries({ queryKey: organizationKeys.detail(id) });
			void queryClient.invalidateQueries({ queryKey: myCompaniesKeys.all });
		},
		onError: () => toaster.error({ title: 'Не удалось удалить компанию' }),
	});
}
