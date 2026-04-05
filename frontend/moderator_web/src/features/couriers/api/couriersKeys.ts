import type { CouriersListParams } from '../types';

export const couriersKeys = {
	all: ['couriers'] as const,
	list: (params?: CouriersListParams) =>
		[...couriersKeys.all, 'list', params] as const,
	detail: (id: number) => [...couriersKeys.all, 'detail', id] as const,
	shifts: () => [...couriersKeys.all, 'shifts'] as const,
};
