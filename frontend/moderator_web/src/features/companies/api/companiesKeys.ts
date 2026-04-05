import type { CompaniesListParams } from '../types';

export const companiesKeys = {
	all: ['companies'] as const,
	list: (params?: CompaniesListParams) =>
		[...companiesKeys.all, 'list', params] as const,
	detail: (id: number) => [...companiesKeys.all, 'detail', id] as const,
	outlets: (id: number) => [...companiesKeys.all, 'outlets', id] as const,
	menu: (id: number) => [...companiesKeys.all, 'menu', id] as const,
};
