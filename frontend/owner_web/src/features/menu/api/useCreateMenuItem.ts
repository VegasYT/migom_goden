import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { menuApi } from './menuApi';
import { menuKeys } from './useMenu';
import type { CreateMenuItemDto } from '../types';

export function useCreateMenuItem() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ companyId, dto }: { companyId: number; dto: CreateMenuItemDto }) =>
			menuApi.createItem(companyId, dto),
		onSuccess: (_, { companyId }) => {
			void queryClient.invalidateQueries({ queryKey: menuKeys.company(companyId) });
			toaster.success({ title: 'Позиция добавлена' });
		},
		onError: () => toaster.error({ title: 'Не удалось добавить позицию' }),
	});
}
