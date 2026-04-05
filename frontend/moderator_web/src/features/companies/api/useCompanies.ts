import { useQuery } from '@tanstack/react-query';
import { companiesApi } from './companiesApi';
import { companiesKeys } from './companiesKeys';
import type { CompaniesListParams } from '../types';

export function useCompanies(params: CompaniesListParams) {
	return useQuery({
		queryKey: companiesKeys.list(params),
		queryFn: () => companiesApi.getAll(params),
	});
}
