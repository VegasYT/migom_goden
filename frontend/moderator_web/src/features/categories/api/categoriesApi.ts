import { httpClient } from '@shared/api/httpClient';
import type { Category, CreateCategoryDto, UpdateCategoryDto } from '../types';

export const categoriesApi = {
	getAll: (params?: { search?: string }) =>
		httpClient
			.get<Category[]>('/api/v1/categories/all', { params })
			.then((r) => r.data),

	create: (dto: CreateCategoryDto) =>
		httpClient
			.post<Category>('/api/v1/categories', dto)
			.then((r) => r.data),

	update: (id: number, dto: UpdateCategoryDto) =>
		httpClient
			.patch<Category>(`/api/v1/categories/${id}`, dto)
			.then((r) => r.data),

	delete: (id: number) => httpClient.delete(`/api/v1/categories/${id}`),
};
