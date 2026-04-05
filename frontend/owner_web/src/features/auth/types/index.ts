// types/index.ts - TypeScript типы фичи auth

export interface TokenResponse {
	access_token: string;
	refresh_token: string;
	token_type: string;
}

export interface LoginDto {
	email: string;
	password: string;
}

export interface RegisterDto {
	email: string;
	password: string;
	full_name: string;
	phone?: string;
	role_id: number;
}

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
