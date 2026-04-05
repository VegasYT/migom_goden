import { httpClient } from '@shared/api/httpClient';
import type {
	CompanyMenu,
	MenuItem,
	GlobalCategory,
	CreateMenuItemDto,
	UpdateMenuItemDto,
} from '../types';

export const menuApi = {
	getMenu: (companyId: number) =>
		httpClient
			.get<CompanyMenu>(`/api/v1/companies/${companyId}/menu`)
			.then((r) => r.data),

	getGlobalCategories: () =>
		httpClient.get<GlobalCategory[]>('/api/v1/categories').then((r) => r.data),

	createItem: (companyId: number, dto: CreateMenuItemDto) =>
		httpClient
			.post<MenuItem>(`/api/v1/companies/${companyId}/items`, dto)
			.then((r) => r.data),

	updateItem: (companyId: number, itemId: number, dto: UpdateMenuItemDto) =>
		httpClient
			.patch<MenuItem>(`/api/v1/companies/${companyId}/items/${itemId}`, dto)
			.then((r) => r.data),

	deleteItem: (companyId: number, itemId: number) =>
		httpClient.delete(`/api/v1/companies/${companyId}/items/${itemId}`),

	uploadItemPhoto: (companyId: number, itemId: number, file: File) => {
		const formData = new FormData();
		formData.append('file', file);
		return httpClient
			.post<MenuItem>(
				`/api/v1/companies/${companyId}/items/${itemId}/photo`,
				formData,
			)
			.then((r) => r.data);
	},
};
