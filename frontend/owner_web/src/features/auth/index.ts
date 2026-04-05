// features/auth/index.ts - barrel: публичный API фичи

export { LoginForm } from './ui/LoginForm';
export { RegisterForm } from './ui/RegisterForm';
export { useAuthStore } from './model/authStore';
export { useLogin } from './api/useLogin';
export { useRegister } from './api/useRegister';
export { useAuthGuard, useOutletManagerGuard, useGuestGuard } from './lib/useAuthGuard';
export { ROLE_OWNER, ROLE_OUTLET_MANAGER } from './types';
export type { AuthUser, AuthRole, LoginDto, RegisterDto, TokenResponse } from './types';
