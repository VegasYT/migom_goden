import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { ordersApi } from './ordersApi';
import { ordersKeys } from './useOrders';

type Action = 'assemble' | 'ready' | 'cancel';

const actionFns = {
	assemble: ordersApi.assemble,
	ready: ordersApi.ready,
	cancel: ordersApi.cancel,
} as const;

const successMessages: Record<Action, string> = {
	assemble: 'Заказ взят в сборку',
	ready: 'Заказ готов к выдаче',
	cancel: 'Заказ отменён',
};

export function useOrderAction() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ orderId, action }: { orderId: number; action: Action }) =>
			actionFns[action](orderId),
		onSuccess: (_, { action }) => {
			void queryClient.invalidateQueries({ queryKey: ordersKeys.all });
			toaster.success({ title: successMessages[action] });
		},
		onError: (error: { response?: { data?: { detail?: string } } }) => {
			const detail = error.response?.data?.detail ?? 'Не удалось выполнить действие';
			toaster.error({ title: detail });
		},
	});
}
