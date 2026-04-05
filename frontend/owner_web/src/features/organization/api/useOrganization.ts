import { useQuery } from '@tanstack/react-query';
import { organizationApi } from './organizationApi';

export const organizationKeys = {
	all: ['organization'] as const,
	detail: (id: number) => [...organizationKeys.all, 'detail', id] as const,
};

export function useOrganization(id: number | null) {
	return useQuery({
		queryKey: organizationKeys.detail(id!),
		queryFn: () => organizationApi.getById(id!),
		enabled: id !== null,
	});
}
