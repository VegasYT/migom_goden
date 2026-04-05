import { useMutation, useQueryClient } from '@tanstack/react-query';
import { companiesApi } from './companiesApi';
import { companiesKeys } from './companiesKeys';
import { toaster } from '@shared/ui/toaster';

export function useBlockCompany() {
	const queryClient = useQueryClient();

	return useMutation({
		mutationFn: ({ id, blocked }: { id: number; blocked: boolean }) =>
			blocked ? companiesApi.unblock(id) : companiesApi.block(id),
		onSuccess: (updatedCompany) => {
			queryClient.setQueryData(
				companiesKeys.detail(updatedCompany.id),
				updatedCompany
			);
			void queryClient.invalidateQueries({ queryKey: companiesKeys.all });
			toaster.success({
				title: updatedCompany.is_blocked
					? 'Компания заблокирована'
					: 'Компания разблокирована',
			});
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail =
				error.response?.data?.detail ??
				'Не удалось изменить статус блокировки';
			toaster.error({ title: detail });
		},
	});
}
