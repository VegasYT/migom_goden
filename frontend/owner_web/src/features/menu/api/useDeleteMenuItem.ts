import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { menuApi } from './menuApi';
import { menuKeys } from './useMenu';

export function useDeleteMenuItem() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ companyId, itemId }: { companyId: number; itemId: number }) =>
			menuApi.deleteItem(companyId, itemId),
		onSuccess: (_, { companyId }) => {
			void queryClient.invalidateQueries({ queryKey: menuKeys.company(companyId) });
			toaster.success({ title: 'Позиция удалена' });
		},
		onError: () => toaster.error({ title: 'Не удалось удалить позицию' }),
	});
}
