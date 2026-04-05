import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { outletsApi } from './outletsApi';
import { itemsAvailabilityKeys } from './useItemsAvailability';
import type { ItemAvailabilityUpdate } from '../types';

export function useSetItemAvailability() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			outletId,
			itemId,
			dto,
		}: {
			outletId: number;
			itemId: number;
			dto: ItemAvailabilityUpdate;
		}) => outletsApi.setItemAvailability(outletId, itemId, dto),
		onSuccess: (_, { outletId }) => {
			void queryClient.invalidateQueries({
				queryKey: itemsAvailabilityKeys.outlet(outletId),
			});
		},
		onError: () =>
			toaster.error({ title: 'Не удалось изменить доступность' }),
	});
}
