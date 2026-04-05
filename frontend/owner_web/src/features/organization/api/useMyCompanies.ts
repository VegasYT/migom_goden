import { useQuery } from '@tanstack/react-query';
import { organizationApi } from './organizationApi';

export const myCompaniesKeys = {
	all: ['my-companies'] as const,
};

export function useMyCompanies() {
	return useQuery({
		queryKey: myCompaniesKeys.all,
		queryFn: () => organizationApi.getMy(),
	});
}
