import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { menuApi } from './menuApi';
import { menuKeys } from './useMenu';
import type { UpdateCategoryDto } from '../types';

export function useUpdateCategory() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			companyId,
			categoryId,
			dto,
		}: {
			companyId: number;
			categoryId: number;
			dto: UpdateCategoryDto;
		}) => menuApi.updateCategory(companyId, categoryId, dto),
		onSuccess: (_, { companyId }) => {
			void queryClient.invalidateQueries({ queryKey: menuKeys.company(companyId) });
			toaster.success({ title: 'Категория обновлена' });
		},
		onError: () => toaster.error({ title: 'Не удалось обновить категорию' }),
	});
}
