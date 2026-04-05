import { useQuery } from '@tanstack/react-query';
import { couriersApi } from './couriersApi';
import { couriersKeys } from './couriersKeys';
import type { CouriersListParams } from '../types';

export function useCouriersList(params: CouriersListParams) {
	return useQuery({
		queryKey: couriersKeys.list(params),
		queryFn: () => couriersApi.getAll(params),
	});
}
