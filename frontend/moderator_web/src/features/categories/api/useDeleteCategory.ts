import { useMutation, useQueryClient } from '@tanstack/react-query';
import { categoriesApi } from './categoriesApi';
import { categoriesKeys } from './categoriesKeys';
import { toaster } from '@shared/ui/toaster';

export function useDeleteCategory() {
	const queryClient = useQueryClient();

	return useMutation({
		mutationFn: (id: number) => categoriesApi.delete(id),
		onSuccess: () => {
			void queryClient.invalidateQueries({ queryKey: categoriesKeys.all });
			toaster.success({ title: 'Категория удалена' });
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail =
				error.response?.data?.detail ?? 'Не удалось удалить категорию';
			toaster.error({ title: detail });
		},
	});
}
