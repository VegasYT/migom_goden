import { useQuery } from '@tanstack/react-query';
import { companiesApi } from './companiesApi';
import { companiesKeys } from './companiesKeys';

export function useCompanyMenu(companyId: number | null) {
	return useQuery({
		queryKey: companiesKeys.menu(companyId!),
		queryFn: () => companiesApi.getMenu(companyId!),
		enabled: companyId !== null,
	});
}
