import { useMutation, useQueryClient } from '@tanstack/react-query';
import { companiesApi } from './companiesApi';
import { companiesKeys } from './companiesKeys';
import { toaster } from '@shared/ui/toaster';

export function useDeleteCompany() {
	const queryClient = useQueryClient();

	return useMutation({
		mutationFn: (id: number) => companiesApi.delete(id),
		onSuccess: (_, id) => {
			queryClient.removeQueries({ queryKey: companiesKeys.detail(id) });
			void queryClient.invalidateQueries({ queryKey: companiesKeys.all });
			toaster.success({ title: 'Компания удалена' });
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail =
				error.response?.data?.detail ?? 'Не удалось удалить компанию';
			toaster.error({ title: detail });
		},
	});
}
