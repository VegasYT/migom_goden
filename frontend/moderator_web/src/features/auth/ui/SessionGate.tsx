import type { ReactNode } from 'react';
import { isAxiosError } from 'axios';
import { useQuery } from '@tanstack/react-query';
import { Alert, Box, Button, CircularProgress } from '@mui/material';
import { authApi } from '../api/authApi';
import { useAuthStore } from '../model/authStore';

const DENIED = 'Кабинет модератора доступен только модераторам Мигома.';

/** Показывает кабинет только модератору; остальным предлагает выйти и войти другим аккаунтом. */
export function SessionGate({ children }: { children: ReactNode }) {
	const user = useAuthStore((s) => s.user);
	const setUser = useAuthStore((s) => s.setUser);
	const logout = useAuthStore((s) => s.logout);
	const session = useQuery({
		queryKey: ['auth', 'session'],
		queryFn: async () => {
			const found = await authApi.session();
			if (found.role.name === 'moderator') setUser(found);
			return found;
		},
		retry: false,
		staleTime: Infinity,
	});

	if (user) return children;
	if (session.isPending) {
		return (
			<Centered>
				<CircularProgress />
			</Centered>
		);
	}
	const detail = isAxiosError<{ detail?: string }>(session.error) ? session.error.response?.data?.detail : undefined;
	// нового пользователя кабинет модератора не заводит, поэтому для него это тот же отказ
	const denied = Boolean(session.data) || detail === 'registration_required';
	return (
		<Centered>
			<Alert severity={denied ? 'warning' : 'error'} sx={{ maxWidth: 480 }}>
				{denied ? DENIED : (detail ?? 'Не удалось войти в кабинет. Попробуйте позже.')}
			</Alert>
			<Button onClick={logout}>Выйти</Button>
		</Centered>
	);
}

function Centered({ children }: { children: ReactNode }) {
	return (
		<Box
			sx={{
				minHeight: '100vh',
				display: 'flex',
				flexDirection: 'column',
				alignItems: 'center',
				justifyContent: 'center',
				gap: 2,
				p: 2,
			}}
		>
			{children}
		</Box>
	);
}
