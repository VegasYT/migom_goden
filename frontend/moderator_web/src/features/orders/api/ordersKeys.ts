import type { OrdersListParams } from '../types';

export const ordersKeys = {
	all: ['orders'] as const,
	list: (params?: OrdersListParams) =>
		[...ordersKeys.all, 'list', params] as const,
	couriers: () => ['couriers'] as const,
};
