import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { menuApi } from './menuApi';
import { menuKeys } from './useMenu';
import type { CompanyMenu, UpdateMenuItemDto } from '../types';

export function useUpdateMenuItem() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			companyId,
			itemId,
			dto,
		}: {
			companyId: number;
			itemId: number;
			dto: UpdateMenuItemDto;
		}) => menuApi.updateItem(companyId, itemId, dto),
		onSuccess: (updatedItem, { companyId }) => {
			const cached = queryClient.getQueryData<CompanyMenu>(menuKeys.company(companyId));
			const oldItem = cached?.categories.flatMap((c) => c.items).find((i) => i.id === updatedItem.id);

			if (oldItem && oldItem.category_id !== updatedItem.category_id) {
				// Category changed - full refetch to move the item to the right section
				void queryClient.invalidateQueries({ queryKey: menuKeys.company(companyId) });
			} else {
				// Update item in place so inactive items stay visible with "Скрыт" badge
				queryClient.setQueryData<CompanyMenu>(menuKeys.company(companyId), (old) => {
					if (!old) return old;
					return {
						...old,
						categories: old.categories.map((cat) => ({
							...cat,
							items: cat.items.map((item) =>
								item.id === updatedItem.id ? updatedItem : item,
							),
						})),
					};
				});
			}
			toaster.success({ title: 'Позиция обновлена' });
		},
		onError: () => toaster.error({ title: 'Не удалось обновить позицию' }),
	});
}
