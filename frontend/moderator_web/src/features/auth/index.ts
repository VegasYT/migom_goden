// features/auth/index.ts - barrel: публичный API фичи

export { LoginForm } from './ui/LoginForm';
export { useAuthStore } from './model/authStore';
export { useLogin } from './api/useLogin';
export { useAuthGuard, useGuestGuard } from './lib/useAuthGuard';
export type { AuthUser, LoginDto, TokenResponse } from './types';
