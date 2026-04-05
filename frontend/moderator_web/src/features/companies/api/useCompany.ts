import { useQuery } from '@tanstack/react-query';
import { companiesApi } from './companiesApi';
import { companiesKeys } from './companiesKeys';

export function useCompany(id: number | null) {
	return useQuery({
		queryKey: companiesKeys.detail(id!),
		queryFn: () => companiesApi.getById(id!),
		enabled: id !== null,
	});
}
