import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { outletsApi } from './outletsApi';
import { outletsKeys } from './useOutlets';
import type { CreateOutletDto } from '../types';

export function useCreateOutlet() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ companyId, dto }: { companyId: number; dto: CreateOutletDto }) =>
			outletsApi.createOutlet(companyId, dto),
		onSuccess: (_, { companyId }) => {
			void queryClient.invalidateQueries({ queryKey: outletsKeys.company(companyId) });
			toaster.success({ title: 'Точка продаж создана' });
		},
		onError: () => toaster.error({ title: 'Не удалось создать точку продаж' }),
	});
}
