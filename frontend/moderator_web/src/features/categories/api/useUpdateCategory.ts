import { useMutation, useQueryClient } from '@tanstack/react-query';
import { categoriesApi } from './categoriesApi';
import { categoriesKeys } from './categoriesKeys';
import { toaster } from '@shared/ui/toaster';
import type { UpdateCategoryDto } from '../types';

export function useUpdateCategory() {
	const queryClient = useQueryClient();

	return useMutation({
		mutationFn: ({ id, dto }: { id: number; dto: UpdateCategoryDto }) =>
			categoriesApi.update(id, dto),
		onSuccess: () => {
			void queryClient.invalidateQueries({ queryKey: categoriesKeys.all });
			toaster.success({ title: 'Категория обновлена' });
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail =
				error.response?.data?.detail ?? 'Не удалось обновить категорию';
			toaster.error({ title: detail });
		},
	});
}
