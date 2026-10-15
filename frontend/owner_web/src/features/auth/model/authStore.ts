import { create } from 'zustand';
import { logout as keycloakLogout } from '@shared/auth/keycloak';
import type { AuthUser } from '../types';

interface AuthStore {
	user: AuthUser | null;
	isAuthenticated: boolean;
	setUser: (user: AuthUser) => void;
	logout: () => void;
}

/** Пользователь Мигома текущей сессии Keycloak; его заполняет SessionGate до показа кабинета. */
export const useAuthStore = create<AuthStore>()((set) => ({
	user: null,
	isAuthenticated: false,
	setUser: (user) => set({ user, isAuthenticated: true }),
	logout: () => void keycloakLogout(),
}));
