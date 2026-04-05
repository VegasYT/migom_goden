import { httpClient } from '@shared/api/httpClient';
import type {
	Outlet,
	CreateOutletDto,
	UpdateOutletDto,
	OutletMenu,
	ItemAvailabilityWithInfo,
	ItemAvailabilityUpdate,
	ItemAvailabilityResponse,
	OutletManager,
	AddManagerDto,
} from '../types';

export const outletsApi = {
	getOutlets: (companyId: number) =>
		httpClient
			.get<Outlet[]>(`/api/v1/companies/${companyId}/outlets`)
			.then((r) => r.data),

	createOutlet: (companyId: number, dto: CreateOutletDto) =>
		httpClient
			.post<Outlet>(`/api/v1/companies/${companyId}/outlets`, dto)
			.then((r) => r.data),

	updateOutlet: (outletId: number, dto: UpdateOutletDto) =>
		httpClient
			.patch<Outlet>(`/api/v1/outlets/${outletId}`, dto)
			.then((r) => r.data),

	deleteOutlet: (outletId: number) =>
		httpClient.delete(`/api/v1/outlets/${outletId}`),

	getItemsAvailability: (outletId: number) =>
		httpClient
			.get<ItemAvailabilityWithInfo[]>(`/api/v1/outlets/${outletId}/items/availability`)
			.then((r) => r.data),

	getOutletMenu: (outletId: number) =>
		httpClient
			.get<OutletMenu>(`/api/v1/outlets/${outletId}/menu`)
			.then((r) => r.data),

	setItemAvailability: (
		outletId: number,
		itemId: number,
		dto: ItemAvailabilityUpdate,
	) =>
		httpClient
			.patch<ItemAvailabilityResponse>(
				`/api/v1/outlets/${outletId}/items/${itemId}/availability`,
				dto,
			)
			.then((r) => r.data),

	getManagers: (outletId: number) =>
		httpClient
			.get<OutletManager[]>(`/api/v1/outlets/${outletId}/managers`)
			.then((r) => r.data),

	addManager: (outletId: number, dto: AddManagerDto) =>
		httpClient
			.post<OutletManager>(`/api/v1/outlets/${outletId}/managers`, dto)
			.then((r) => r.data),

	removeManager: (outletId: number, userId: number) =>
		httpClient.delete(`/api/v1/outlets/${outletId}/managers/${userId}`),
};
