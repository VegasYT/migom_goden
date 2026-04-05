import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { AuthUser } from '../types';

interface AuthStore {
	accessToken: string | null;
	refreshToken: string | null;
	user: AuthUser | null;
	isAuthenticated: boolean;
	setAuth: (accessToken: string, refreshToken: string, user?: AuthUser) => void;
	setUser: (user: AuthUser) => void;
	setTokens: (accessToken: string, refreshToken: string) => void;
	logout: () => void;
}

export const useAuthStore = create<AuthStore>()(
	persist(
		(set) => ({
			accessToken: null,
			refreshToken: null,
			user: null,
			isAuthenticated: false,

			setAuth: (accessToken, refreshToken, user) =>
				set({ accessToken, refreshToken, user, isAuthenticated: true }),

			setUser: (user) => set({ user }),

			setTokens: (accessToken, refreshToken) =>
				set({ accessToken, refreshToken }),

			logout: () =>
				set({ accessToken: null, refreshToken: null, user: null, isAuthenticated: false }),
		}),
		{
			name: 'migom-auth',
			partialize: (state) => ({
				accessToken: state.accessToken,
				refreshToken: state.refreshToken,
				isAuthenticated: state.isAuthenticated,
				user: state.user,
			}),
		},
	),
);
