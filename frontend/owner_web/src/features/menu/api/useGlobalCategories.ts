import { useQuery } from '@tanstack/react-query';
import { menuApi } from './menuApi';

export const globalCategoriesKeys = {
	all: ['global-categories'] as const,
};

export function useGlobalCategories() {
	return useQuery({
		queryKey: globalCategoriesKeys.all,
		queryFn: () => menuApi.getGlobalCategories(),
		staleTime: 10 * 60 * 1000,
	});
}
