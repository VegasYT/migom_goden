import { useQuery } from '@tanstack/react-query';
import { ordersApi } from './ordersApi';
import type { OrdersFilter } from '../types';

export const ordersKeys = {
	all: ['orders'] as const,
	list: (filter: OrdersFilter) => [...ordersKeys.all, 'list', filter] as const,
};

export function useOrders(filter: OrdersFilter) {
	return useQuery({
		queryKey: ordersKeys.list(filter),
		queryFn: () => ordersApi.getOrders(filter),
	});
}
