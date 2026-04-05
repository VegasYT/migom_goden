export interface Category {
	id: number;
	name: string;
	emoji: string;
	sort_order: number;
	is_active: boolean;
}

export interface CreateCategoryDto {
	name: string;
	emoji: string;
	sort_order?: number;
}

export interface UpdateCategoryDto {
	name?: string | null;
	emoji?: string | null;
	sort_order?: number | null;
	is_active?: boolean | null;
}
