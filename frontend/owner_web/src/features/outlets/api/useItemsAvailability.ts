import { useQuery } from '@tanstack/react-query';
import { outletsApi } from './outletsApi';

export const itemsAvailabilityKeys = {
	all: ['outlet-items-availability'] as const,
	outlet: (outletId: number) => [...itemsAvailabilityKeys.all, outletId] as const,
};

export function useItemsAvailability(outletId: number | null) {
	return useQuery({
		queryKey: itemsAvailabilityKeys.outlet(outletId!),
		queryFn: () => outletsApi.getItemsAvailability(outletId!),
		enabled: outletId !== null,
	});
}
