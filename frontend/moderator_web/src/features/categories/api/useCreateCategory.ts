import { useMutation, useQueryClient } from '@tanstack/react-query';
import { categoriesApi } from './categoriesApi';
import { categoriesKeys } from './categoriesKeys';
import { toaster } from '@shared/ui/toaster';
import type { CreateCategoryDto } from '../types';

export function useCreateCategory() {
	const queryClient = useQueryClient();

	return useMutation({
		mutationFn: (dto: CreateCategoryDto) => categoriesApi.create(dto),
		onSuccess: () => {
			void queryClient.invalidateQueries({ queryKey: categoriesKeys.all });
			toaster.success({ title: 'Категория создана' });
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail =
				error.response?.data?.detail ?? 'Не удалось создать категорию';
			toaster.error({ title: detail });
		},
	});
}
