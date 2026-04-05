import { httpClient } from '@shared/api/httpClient';
import type { Order, OrderListResponse, OrdersFilter } from '../types';

export const ordersApi = {
	getOrders: (filter: OrdersFilter) =>
		httpClient
			.get<OrderListResponse>('/api/v1/outlet/orders', { params: filter })
			.then((r) => r.data),

	assemble: (orderId: number) =>
		httpClient
			.post<Order>(`/api/v1/outlet/orders/${orderId}/assemble`)
			.then((r) => r.data),

	ready: (orderId: number) =>
		httpClient
			.post<Order>(`/api/v1/outlet/orders/${orderId}/ready`)
			.then((r) => r.data),

	cancel: (orderId: number) =>
		httpClient
			.post<Order>(`/api/v1/outlet/orders/${orderId}/cancel`)
			.then((r) => r.data),
};
