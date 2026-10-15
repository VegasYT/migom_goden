// types/index.ts - TypeScript типы фичи auth

export interface AuthRole {
	id: number;
	name: string;
}

export interface AuthUser {
	id: number;
	email: string;
	full_name: string;
	phone: string | null;
	avatar_url: string | null;
	is_active: boolean;
	role: AuthRole;
}

export const ROLE_OWNER = 2;
export const ROLE_OUTLET_MANAGER = 5;
