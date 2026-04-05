export interface MenuItem {
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

export interface MenuCategory {
	id: number;
	name: string;
	emoji: string;
	sort_order: number;
	is_active: boolean;
	items: MenuItem[];
}

export interface GlobalCategory {
	id: number;
	name: string;
	emoji: string;
	sort_order: number;
	is_active: boolean;
}

export interface CompanyMenu {
	company_id: number;
	categories: MenuCategory[];
}

export interface CreateMenuItemDto {
	category_id: number;
	name: string;
	description?: string;
	price: string;
}

export interface UpdateMenuItemDto {
	category_id?: number;
	name?: string;
	description?: string;
	price?: string;
	is_active?: boolean;
}
