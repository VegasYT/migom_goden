import { httpClient } from '@shared/api/httpClient';
import type {
	Company,
	CompaniesListResponse,
	CompaniesListParams,
	Outlet,
	CompanyMenu,
} from '../types';

export const companiesApi = {
	getAll: (params?: CompaniesListParams) =>
		httpClient
			.get<CompaniesListResponse>('/api/v1/companies', { params })
			.then((r) => r.data),

	getById: (id: number) =>
		httpClient.get<Company>(`/api/v1/companies/${id}`).then((r) => r.data),

	block: (id: number) =>
		httpClient
			.post<Company>(`/api/v1/companies/${id}/block`)
			.then((r) => r.data),

	unblock: (id: number) =>
		httpClient
			.post<Company>(`/api/v1/companies/${id}/unblock`)
			.then((r) => r.data),

	delete: (id: number) => httpClient.delete(`/api/v1/companies/${id}`),

	getOutlets: (companyId: number) =>
		httpClient
			.get<Outlet[]>(`/api/v1/companies/${companyId}/outlets`)
			.then((r) => r.data),

	getMenu: (companyId: number) =>
		httpClient
			.get<CompanyMenu>(`/api/v1/companies/${companyId}/menu`)
			.then((r) => r.data),
};
