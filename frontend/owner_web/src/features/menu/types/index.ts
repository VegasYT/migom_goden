export interface MenuItem {
	id: number;
	category_id: number;
	company_id: number;
	name: string;
	description: string | null;
	price: string;
	photo_url: string | null;
	is_active: boolean;
	goden_dish_id: string | null;
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
	goden_dish_id?: string;
}

export interface UpdateMenuItemDto {
	category_id?: number;
	name?: string;
	description?: string;
	price?: string;
	is_active?: boolean;
	// null снимает связь с блюдом Goden
	goden_dish_id?: string | null;
}
