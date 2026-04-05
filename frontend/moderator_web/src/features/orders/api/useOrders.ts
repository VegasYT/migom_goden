import { useQuery } from '@tanstack/react-query';
import { ordersApi } from './ordersApi';
import { ordersKeys } from './ordersKeys';
import type { OrdersListParams } from '../types';

export function useOrders(params: OrdersListParams) {
	return useQuery({
		queryKey: ordersKeys.list(params),
		queryFn: () => ordersApi.getAll(params),
	});
}
