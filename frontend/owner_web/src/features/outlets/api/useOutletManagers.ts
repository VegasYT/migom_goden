import { useQuery } from '@tanstack/react-query';
import { outletsApi } from './outletsApi';

export const outletManagersKeys = {
	all: ['outlet-managers'] as const,
	outlet: (outletId: number) => [...outletManagersKeys.all, outletId] as const,
};

export function useOutletManagers(outletId: number | null) {
	return useQuery({
		queryKey: outletManagersKeys.outlet(outletId!),
		queryFn: () => outletsApi.getManagers(outletId!),
		enabled: outletId !== null,
	});
}
