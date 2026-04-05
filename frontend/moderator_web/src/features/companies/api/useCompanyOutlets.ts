import { useQuery } from '@tanstack/react-query';
import { companiesApi } from './companiesApi';
import { companiesKeys } from './companiesKeys';

export function useCompanyOutlets(companyId: number | null) {
	return useQuery({
		queryKey: companiesKeys.outlets(companyId!),
		queryFn: () => companiesApi.getOutlets(companyId!),
		enabled: companyId !== null,
	});
}
