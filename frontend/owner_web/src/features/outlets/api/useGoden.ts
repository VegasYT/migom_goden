import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { httpClient } from '@shared/api/httpClient';
import { toaster } from '@shared/ui/toaster';
import { menuKeys } from '@features/menu';
import type { MenuItem } from '@features/menu';
import { outletsKeys } from './useOutlets';
import type { GodenDish, GodenPoint, Outlet } from '../types';

export const godenKeys = {
	points: ['goden-points'] as const,
	dishes: (outletId: number) => ['goden-dishes', outletId] as const,
};

type ApiError = { response?: { data?: { detail?: string } } };

// текст ошибки от business_service: Goden недоступен, чужая или занятая точка
function showError(fallback: string) {
	return (error: ApiError) => toaster.error({ title: error.response?.data?.detail ?? fallback });
}

export function useGodenPoints(enabled: boolean) {
	return useQuery({
		queryKey: godenKeys.points,
		queryFn: () => httpClient.get<GodenPoint[]>('/api/v1/goden/points').then((r) => r.data),
		enabled,
		retry: false,
	});
}

export function useGodenDishes(outletId: number, enabled: boolean) {
	return useQuery({
		queryKey: godenKeys.dishes(outletId),
		queryFn: () =>
			httpClient.get<GodenDish[]>(`/api/v1/outlets/${outletId}/goden/dishes`).then((r) => r.data),
		enabled,
		retry: false,
	});
}

export function useSetGodenPoint(companyId: number) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ outletId, pointId }: { outletId: number; pointId: string | null }) =>
			httpClient
				.put<Outlet>(`/api/v1/outlets/${outletId}/goden`, { point_id: pointId })
				.then((r) => r.data),
		onSuccess: (outlet) => {
			void queryClient.invalidateQueries({ queryKey: outletsKeys.company(companyId) });
			void queryClient.invalidateQueries({ queryKey: godenKeys.points });
			void queryClient.invalidateQueries({ queryKey: godenKeys.dishes(outlet.id) });
			toaster.success({
				title: outlet.goden_point_id ? 'Заведение подключено к Goden' : 'Заведение отключено от Goden',
			});
		},
		onError: showError('Не удалось изменить подключение к Goden'),
	});
}

export function useLinkByName(outletId: number, companyId: number) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: () =>
			httpClient
				.post<GodenDish[]>(`/api/v1/outlets/${outletId}/goden/link-by-name`)
				.then((r) => r.data),
		onSuccess: (dishes) => {
			queryClient.setQueryData(godenKeys.dishes(outletId), dishes);
			void queryClient.invalidateQueries({ queryKey: menuKeys.company(companyId) });
		},
		onError: showError('Не удалось связать блюда'),
	});
}

// связь товара с блюдом: dishId null снимает её
export function useLinkDish(outletId: number, companyId: number) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ itemId, dishId }: { itemId: number; dishId: string | null }) =>
			httpClient
				.patch<MenuItem>(`/api/v1/companies/${companyId}/items/${itemId}`, { goden_dish_id: dishId })
				.then((r) => r.data),
		onSuccess: () => {
			void queryClient.invalidateQueries({ queryKey: godenKeys.dishes(outletId) });
			void queryClient.invalidateQueries({ queryKey: menuKeys.company(companyId) });
		},
		onError: showError('Не удалось связать товар'),
	});
}

export function useCreateItemFromDish(outletId: number, companyId: number) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: (dto: { dish: GodenDish; categoryId: number; price: string }) =>
			httpClient
				.post<MenuItem>(`/api/v1/companies/${companyId}/items`, {
					name: dto.dish.name,
					category_id: dto.categoryId,
					price: dto.price,
					goden_dish_id: dto.dish.id,
				})
				.then((r) => r.data),
		onSuccess: () => {
			void queryClient.invalidateQueries({ queryKey: godenKeys.dishes(outletId) });
			void queryClient.invalidateQueries({ queryKey: menuKeys.company(companyId) });
			toaster.success({ title: 'Товар создан' });
		},
		onError: showError('Не удалось создать товар'),
	});
}
