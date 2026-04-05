export type MovementType = 'walk' | 'scooter' | 'car';

export interface Courier {
	id: number;
	user_id: number;
	is_blocked: boolean;
	type_movement: MovementType | null;
	radius_km: number;
	zone_latitude: number | null;
	zone_longitude: number | null;
	current_latitude: number | null;
	current_longitude: number | null;
	location_updated_at: string | null;
}

export interface CouriersListResponse {
	items: Courier[];
	total: number;
}

export interface CouriersListParams {
	offset?: number;
	limit?: number;
}

export interface Shift {
	id: number;
	courier_id: number;
	started_at: string;
	ended_at: string | null;
	is_active: boolean;
}

export interface ActiveShiftsResponse {
	items: Shift[];
	total: number;
}

export const MOVEMENT_LABEL: Record<MovementType, string> = {
	walk: 'Пешком',
	scooter: 'Самокат',
	car: 'Авто',
};
