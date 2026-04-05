import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { menuApi } from './menuApi';
import { menuKeys } from './useMenu';

export function useDeleteCategory() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ companyId, categoryId }: { companyId: number; categoryId: number }) =>
			menuApi.deleteCategory(companyId, categoryId),
		onSuccess: (_, { companyId }) => {
			void queryClient.invalidateQueries({ queryKey: menuKeys.company(companyId) });
			toaster.success({ title: 'Категория удалена' });
		},
		onError: () => toaster.error({ title: 'Не удалось удалить категорию' }),
	});
}
