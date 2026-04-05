import { useQuery } from '@tanstack/react-query';
import { httpClient } from '@shared/api/httpClient';
import { couriersKeys } from './couriersKeys';
import type { ActiveShiftsResponse } from '../types';

export function useActiveShifts() {
	return useQuery({
		queryKey: couriersKeys.shifts(),
		queryFn: () =>
			httpClient
				.get<ActiveShiftsResponse>('/api/v1/shifts', {
					params: { limit: 100 },
				})
				.then((r) => r.data),
	});
}
