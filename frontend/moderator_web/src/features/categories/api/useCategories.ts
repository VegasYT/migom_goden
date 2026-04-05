import { useQuery } from '@tanstack/react-query';
import { categoriesApi } from './categoriesApi';
import { categoriesKeys } from './categoriesKeys';

export function useCategories(search?: string) {
	return useQuery({
		queryKey: categoriesKeys.list(search),
		queryFn: () => categoriesApi.getAll({ search: search || undefined }),
	});
}
