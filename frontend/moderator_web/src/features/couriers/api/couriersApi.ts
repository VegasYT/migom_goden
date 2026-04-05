import { httpClient } from '@shared/api/httpClient';
import type { Courier, CouriersListResponse, CouriersListParams } from '../types';

export const couriersApi = {
	getAll: (params?: CouriersListParams) =>
		httpClient
			.get<CouriersListResponse>('/api/v1/couriers', { params })
			.then((r) => r.data),

	getById: (id: number) =>
		httpClient
			.get<Courier>(`/api/v1/couriers/${id}`)
			.then((r) => r.data),

	block: (id: number) =>
		httpClient
			.post<Courier>(`/api/v1/couriers/${id}/block`)
			.then((r) => r.data),

	unblock: (id: number) =>
		httpClient
			.post<Courier>(`/api/v1/couriers/${id}/unblock`)
			.then((r) => r.data),
};
