// features/auth/index.ts - barrel: публичный API фичи

export { SessionGate } from './ui/SessionGate';
export { useAuthStore } from './model/authStore';
export { useAuthGuard } from './lib/useAuthGuard';
export type { AuthUser } from './types';
