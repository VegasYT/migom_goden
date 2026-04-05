import { useMutation, useQueryClient } from '@tanstack/react-query';
import { ordersApi } from './ordersApi';
import { ordersKeys } from './ordersKeys';
import { toaster } from '@shared/ui/toaster';

export function useCancelOrder() {
	const queryClient = useQueryClient();

	return useMutation({
		mutationFn: (orderId: number) => ordersApi.cancel(orderId),
		onSuccess: () => {
			void queryClient.invalidateQueries({ queryKey: ordersKeys.all });
			toaster.success({ title: 'Заказ отменён' });
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail =
				error.response?.data?.detail ?? 'Не удалось отменить заказ';
			toaster.error({ title: detail });
		},
	});
}
