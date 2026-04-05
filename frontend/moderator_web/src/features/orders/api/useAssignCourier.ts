import { useMutation, useQueryClient } from '@tanstack/react-query';
import { ordersApi } from './ordersApi';
import { ordersKeys } from './ordersKeys';
import { toaster } from '@shared/ui/toaster';

export function useAssignCourier() {
	const queryClient = useQueryClient();

	return useMutation({
		mutationFn: ({
			orderId,
			courierId,
		}: {
			orderId: number;
			courierId: number;
		}) => ordersApi.assign(orderId, courierId),
		onSuccess: () => {
			void queryClient.invalidateQueries({ queryKey: ordersKeys.all });
			toaster.success({ title: 'Курьер назначен' });
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail =
				error.response?.data?.detail ?? 'Не удалось назначить курьера';
			toaster.error({ title: detail });
		},
	});
}
