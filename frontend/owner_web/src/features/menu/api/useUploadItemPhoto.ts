import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { menuApi } from './menuApi';
import { menuKeys } from './useMenu';

export function useUploadItemPhoto() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			companyId,
			itemId,
			file,
		}: {
			companyId: number;
			itemId: number;
			file: File;
		}) => menuApi.uploadItemPhoto(companyId, itemId, file),
		onSuccess: (_, { companyId }) => {
			void queryClient.invalidateQueries({ queryKey: menuKeys.company(companyId) });
			toaster.success({ title: 'Фото обновлено' });
		},
		onError: () => toaster.error({ title: 'Не удалось загрузить фото' }),
	});
}
