import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { outletsApi } from './outletsApi';
import { outletManagersKeys } from './useOutletManagers';
import type { AddManagerDto } from '../types';

export function useAddManager() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ outletId, dto }: { outletId: number; dto: AddManagerDto }) =>
			outletsApi.addManager(outletId, dto),
		onSuccess: (_, { outletId }) => {
			void queryClient.invalidateQueries({
				queryKey: outletManagersKeys.outlet(outletId),
			});
			toaster.success({ title: 'Менеджер добавлен' });
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail = error.response?.data?.detail ?? 'Не удалось добавить менеджера';
			toaster.error({ title: detail });
		},
	});
}
