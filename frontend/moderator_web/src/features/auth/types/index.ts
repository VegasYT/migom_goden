// types/index.ts - TypeScript типы фичи auth

export interface AuthUser {
	id: number;
	email: string;
	full_name: string;
	phone: string | null;
	avatar_url: string | null;
	is_active: boolean;
	role: { id: number; name: string };
}
