import { useQuery } from '@tanstack/react-query';
import { outletsApi } from './outletsApi';

export const outletsKeys = {
	all: ['outlets'] as const,
	company: (companyId: number) => [...outletsKeys.all, companyId] as const,
};

export function useOutlets(companyId: number | null) {
	return useQuery({
		queryKey: outletsKeys.company(companyId!),
		queryFn: () => outletsApi.getOutlets(companyId!),
		enabled: companyId !== null,
	});
}
