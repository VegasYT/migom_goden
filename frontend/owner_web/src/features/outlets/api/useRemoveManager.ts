import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { outletsApi } from './outletsApi';
import { outletManagersKeys } from './useOutletManagers';

export function useRemoveManager() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ outletId, userId }: { outletId: number; userId: number }) =>
			outletsApi.removeManager(outletId, userId),
		onSuccess: (_, { outletId }) => {
			void queryClient.invalidateQueries({
				queryKey: outletManagersKeys.outlet(outletId),
			});
			toaster.success({ title: 'Менеджер удалён' });
		},
		onError: () => toaster.error({ title: 'Не удалось удалить менеджера' }),
	});
}
