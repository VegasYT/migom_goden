import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { outletsApi } from './outletsApi';
import { outletsKeys } from './useOutlets';

export function useDeleteOutlet() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ companyId, outletId }: { companyId: number; outletId: number }) =>
			outletsApi.deleteOutlet(outletId),
		onSuccess: (_, { companyId }) => {
			void queryClient.invalidateQueries({ queryKey: outletsKeys.company(companyId) });
			toaster.success({ title: 'Точка продаж удалена' });
		},
		onError: () => toaster.error({ title: 'Не удалось удалить точку продаж' }),
	});
}
