import { httpClient } from '@shared/api/httpClient';
import type { CreateOrganizationDto, UpdateOrganizationDto, Organization } from '../types';

export const organizationApi = {
	create: (dto: CreateOrganizationDto) =>
		httpClient.post<Organization>('/api/v1/companies', dto).then((r) => r.data),

	getById: (id: number) =>
		httpClient.get<Organization>(`/api/v1/companies/${id}`).then((r) => r.data),

	getAll: () =>
		httpClient
			.get<{ items: Organization[]; total: number }>('/api/v1/companies')
			.then((r) => r.data),

	getMy: () =>
		httpClient.get<Organization[]>('/api/v1/companies/my').then((r) => r.data),

	update: (id: number, dto: UpdateOrganizationDto) =>
		httpClient.patch<Organization>(`/api/v1/companies/${id}`, dto).then((r) => r.data),

	delete: (id: number) =>
		httpClient.delete(`/api/v1/companies/${id}`),
};
