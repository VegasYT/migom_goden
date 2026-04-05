// features/organization/types/index.ts - TypeScript типы фичи organization

export interface Organization {
	id: number;
	owner_id: number;
	name: string;
	description: string | null;
	logo_url: string | null;
	is_active: boolean;
	is_blocked: boolean;
	created_at: string;
	updated_at: string;
}

export interface CreateOrganizationDto {
	name: string;
	description?: string;
}

export interface UpdateOrganizationDto {
	name?: string | null;
	description?: string | null;
	is_active?: boolean | null;
}
