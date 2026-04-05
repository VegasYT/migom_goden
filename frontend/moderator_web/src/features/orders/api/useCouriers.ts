import { useQuery } from '@tanstack/react-query';
import { ordersApi } from './ordersApi';
import { ordersKeys } from './ordersKeys';

export function useCouriers() {
	return useQuery({
		queryKey: ordersKeys.couriers(),
		queryFn: () => ordersApi.getCouriers({ limit: 100 }),
	});
}
