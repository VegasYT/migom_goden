import { useMutation, useQueryClient } from '@tanstack/react-query';
import { couriersApi } from './couriersApi';
import { couriersKeys } from './couriersKeys';
import { toaster } from '@shared/ui/toaster';

export function useBlockCourier() {
	const queryClient = useQueryClient();

	return useMutation({
		mutationFn: ({ id, blocked }: { id: number; blocked: boolean }) =>
			blocked ? couriersApi.unblock(id) : couriersApi.block(id),
		onSuccess: (updatedCourier) => {
			queryClient.setQueryData(
				couriersKeys.detail(updatedCourier.id),
				updatedCourier
			);
			void queryClient.invalidateQueries({ queryKey: couriersKeys.all });
			toaster.success({
				title: updatedCourier.is_blocked
					? 'Курьер заблокирован'
					: 'Курьер разблокирован',
			});
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail =
				error.response?.data?.detail ??
				'Не удалось изменить статус курьера';
			toaster.error({ title: detail });
		},
	});
}
