import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { outletsApi } from './outletsApi';
import { outletsKeys } from './useOutlets';
import type { UpdateOutletDto } from '../types';

export function useUpdateOutlet() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			companyId,
			outletId,
			dto,
		}: {
			companyId: number;
			outletId: number;
			dto: UpdateOutletDto;
		}) => outletsApi.updateOutlet(outletId, dto),
		onSuccess: (_, { companyId }) => {
			void queryClient.invalidateQueries({ queryKey: outletsKeys.company(companyId) });
			toaster.success({ title: 'Точка продаж обновлена' });
		},
		onError: () => toaster.error({ title: 'Не удалось обновить точку продаж' }),
	});
}
