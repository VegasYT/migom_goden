import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { menuApi } from './menuApi';
import { menuKeys } from './useMenu';
import type { CreateCategoryDto } from '../types';

export function useCreateCategory() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ companyId, dto }: { companyId: number; dto: CreateCategoryDto }) =>
			menuApi.createCategory(companyId, dto),
		onSuccess: (_, { companyId }) => {
			void queryClient.invalidateQueries({ queryKey: menuKeys.company(companyId) });
			toaster.success({ title: 'Категория создана' });
		},
		onError: () => toaster.error({ title: 'Не удалось создать категорию' }),
	});
}
