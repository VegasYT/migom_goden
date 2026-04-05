import { httpClient } from '@shared/api/httpClient';
import type {
	Order,
	OrdersListResponse,
	OrdersListParams,
	CouriersListResponse,
} from '../types';

export const ordersApi = {
	getAll: (params?: OrdersListParams) =>
		httpClient
			.get<OrdersListResponse>('/api/v1/admin/orders', { params })
			.then((r) => r.data),

	assign: (orderId: number, courierId: number) =>
		httpClient
			.post<Order>(
				`/api/v1/admin/orders/${orderId}/assign/${courierId}`
			)
			.then((r) => r.data),

	cancel: (orderId: number) =>
		httpClient
			.post<Order>(`/api/v1/admin/orders/${orderId}/cancel`)
			.then((r) => r.data),

	getCouriers: (params?: { offset?: number; limit?: number }) =>
		httpClient
			.get<CouriersListResponse>('/api/v1/couriers', { params })
			.then((r) => r.data),
};
