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

export interface AuthUser {
	id: number;
	email: string;
	full_name: string;
	phone: string | null;
	avatar_url: string | null;
	is_active: boolean;
}
