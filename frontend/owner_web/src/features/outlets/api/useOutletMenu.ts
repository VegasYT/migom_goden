import { useQuery } from '@tanstack/react-query';
import { outletsApi } from './outletsApi';

export const outletMenuKeys = {
	all: ['outlet-menu'] as const,
	outlet: (outletId: number) => [...outletMenuKeys.all, outletId] as const,
};

export function useOutletMenu(outletId: number | null) {
	return useQuery({
		queryKey: outletMenuKeys.outlet(outletId!),
		queryFn: () => outletsApi.getOutletMenu(outletId!),
		enabled: outletId !== null,
	});
}
