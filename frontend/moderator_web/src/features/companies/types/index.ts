export interface Company {
	id: number;
	owner_id: number;
	name: string;
	description: string | null;
	cover_url: string | null;
	is_active: boolean;
	is_blocked: boolean;
	created_at: string;
	updated_at: string;
}

export interface CompaniesListResponse {
	items: Company[];
	total: number;
}

export interface CompaniesListParams {
	offset?: number;
	limit?: number;
	search?: string;
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

export interface CatalogItem {
	id: number;
	category_id: number;
	company_id: number;
	name: string;
	description: string | null;
	price: string;
	photo_url: string | null;
	is_active: boolean;
	created_at: string;
	updated_at: string;
}

export interface CategoryWithItems {
	id: number;
	name: string;
	emoji: string;
	sort_order: number;
	is_active: boolean;
	items: CatalogItem[];
}

export interface CompanyMenu {
	company_id: number;
	categories: CategoryWithItems[];
}
