import { useState, type ReactNode } from 'react';
import { isAxiosError } from 'axios';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
	Alert,
	Box,
	Button,
	CircularProgress,
	FormControlLabel,
	Radio,
	RadioGroup,
	TextField,
	Typography,
} from '@mui/material';
import { organizationApi, useOrganizationStore } from '@features/organization';
import { authApi } from '../api/authApi';
import { useAuthStore } from '../model/authStore';
import { ROLE_OUTLET_MANAGER, ROLE_OWNER, type AuthUser } from '../types';

const sessionKey = ['auth', 'session'] as const;

function errorDetail(error: unknown): string | undefined {
	return isAxiosError<{ detail?: string }>(error) ? error.response?.data?.detail : undefined;
}

/** Показывает кабинет, когда у сессии Keycloak есть пользователь Мигома; новому предлагает выбрать роль. */
export function SessionGate({ children }: { children: ReactNode }) {
	const user = useAuthStore((s) => s.user);
	const setUser = useAuthStore((s) => s.setUser);
	const logout = useAuthStore((s) => s.logout);
	const session = useQuery({
		queryKey: sessionKey,
		queryFn: async () => {
			const found = await authApi.session();
			await chooseCompany(found);
			setUser(found);
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
	if (errorDetail(session.error) === 'registration_required') return <RegistrationStep onDone={setUser} />;
	return (
		<Centered>
			<Alert severity="error" sx={{ maxWidth: 480 }}>
				{errorDetail(session.error) ?? 'Не удалось войти в кабинет. Попробуйте позже.'}
			</Alert>
			<Button onClick={logout}>Выйти</Button>
		</Centered>
	);
}

/** Выбирает владельцу его компанию. Выбор хранится в браузере, поэтому компания прежнего пользователя сбрасывается. */
async function chooseCompany(user: AuthUser) {
	const { companyId, setCompanyId, clearCompany } = useOrganizationStore.getState();
	if (user.role.id === ROLE_OUTLET_MANAGER) {
		clearCompany();
		return;
	}
	try {
		const companies = await organizationApi.getMy();
		if (companies.some((c) => c.id === companyId)) return;
		if (companies.length > 0) setCompanyId(companies[0].id);
		else clearCompany();
	} catch {
		// без списка компаний кабинет не показывает чужую: выбор сбрасывается
		clearCompany();
	}
}

/** Первый вход после регистрации в Keycloak: кто пользователь в Мигоме. */
function RegistrationStep({ onDone }: { onDone: (user: AuthUser) => void }) {
	const queryClient = useQueryClient();
	const logout = useAuthStore((s) => s.logout);
	const [roleId, setRoleId] = useState(ROLE_OWNER);
	const [phone, setPhone] = useState('');
	const register = useMutation({
		mutationFn: async () => {
			const created = await authApi.session({ role_id: roleId, phone: phone.trim() || undefined });
			await chooseCompany(created);
			return created;
		},
		onSuccess: (created) => {
			queryClient.setQueryData(sessionKey, created);
			onDone(created);
		},
	});

	return (
		<Centered>
			<Box sx={{ width: '100%', maxWidth: 420, display: 'flex', flexDirection: 'column', gap: 2 }}>
				<Typography variant="h5" fontWeight={600}>
					Добро пожаловать в Мигом
				</Typography>
				<Typography color="text.secondary">Кто вы? Это нужно один раз, при первом входе.</Typography>
				<RadioGroup value={roleId} onChange={(e) => setRoleId(Number(e.target.value))}>
					<FormControlLabel value={ROLE_OWNER} control={<Radio />} label="Владелец бизнеса" />
					<FormControlLabel value={ROLE_OUTLET_MANAGER} control={<Radio />} label="Менеджер точки" />
				</RadioGroup>
				<TextField
					label="Телефон (необязательно)"
					placeholder="+7 900 000-00-00"
					value={phone}
					onChange={(e) => setPhone(e.target.value)}
				/>
				{register.isError && (
					<Alert severity="error">{errorDetail(register.error) ?? 'Не удалось завершить регистрацию'}</Alert>
				)}
				<Button variant="contained" disabled={register.isPending} onClick={() => register.mutate()}>
					Продолжить
				</Button>
				<Button color="inherit" onClick={logout}>
					Выйти
				</Button>
			</Box>
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
