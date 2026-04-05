export interface ItemAvailabilityWithInfo {
	catalog_item_id: number;
	name: string;
	is_available: boolean;
	stock_count: number | null;
}

export interface ItemAvailabilityUpdate {
	is_available: boolean;
	stock_count?: number | null;
}

export interface ItemAvailabilityResponse {
	outlet_id: number;
	catalog_item_id: number;
	is_available: boolean;
	stock_count: number | null;
}

export interface OutletMenuItem {
	id: number;
	name: string;
	description: string | null;
	price: string;
	photo_url: string | null;
	is_active: boolean;
	stock_count: number | null;
}

export interface OutletMenuCategory {
	id: number;
	name: string;
	emoji: string;
	sort_order: number;
	is_active: boolean;
	items: OutletMenuItem[];
}

export interface OutletMenu {
	outlet_id: number;
	categories: OutletMenuCategory[];
}

export interface Outlet {
	id: number;
	company_id: number;
	name: string;
	address: string;
	latitude: string;
	longitude: string;
	is_active: boolean;
	delivery_fee: number;
	free_delivery_from: number | null;
	min_order_price: number | null;
	opens_at: string;
	closes_at: string;
	timezone: string;
}

export interface CreateOutletDto {
	name: string;
	address: string;
	latitude: string;
	longitude: string;
	delivery_fee?: number;
	free_delivery_from?: number | null;
	min_order_price?: number | null;
	opens_at?: string;
	closes_at?: string;
}

export interface UpdateOutletDto {
	name?: string;
	address?: string;
	latitude?: string;
	longitude?: string;
	is_active?: boolean;
	delivery_fee?: number;
	free_delivery_from?: number | null;
	min_order_price?: number | null;
	opens_at?: string;
	closes_at?: string;
}

export interface OutletManager {
	id: number;
	outlet_id: number;
	user_id: number;
	user_full_name: string;
	user_email: string;
	added_by: number;
	created_at: string;
}

export interface AddManagerDto {
	email: string;
}
