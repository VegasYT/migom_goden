import { useQuery } from '@tanstack/react-query';
import { menuApi } from './menuApi';

export const menuKeys = {
	all: ['menu'] as const,
	company: (companyId: number) => [...menuKeys.all, companyId] as const,
};

export function useMenu(companyId: number | null) {
	return useQuery({
		queryKey: menuKeys.company(companyId!),
		queryFn: () => menuApi.getMenu(companyId!),
		enabled: companyId !== null,
	});
}
