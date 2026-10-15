// features/auth/index.ts - barrel: публичный API фичи

export { SessionGate } from './ui/SessionGate';
export { useAuthStore } from './model/authStore';
export { useAuthGuard, useOutletManagerGuard } from './lib/useAuthGuard';
export { ROLE_OWNER, ROLE_OUTLET_MANAGER } from './types';
export type { AuthUser, AuthRole } from './types';
