import { useState } from 'react';
import {
	Box,
	Typography,
	Button,
	CircularProgress,
	Alert,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import StorefrontOutlinedIcon from '@mui/icons-material/StorefrontOutlined';
import { useAuthGuard, useAuthStore } from '@features/auth';
import {
	useOrganizationGuard,
	useOrganizationStore,
	useOrganization,
} from '@features/organization';
import {
	useOutlets,
	OutletCard,
	OutletDialog,
	OutletsMap,
} from '@features/outlets';
import { AppLayout } from '../layouts/AppLayout';

export default function OutletsPage() {
	useAuthGuard();
	useOrganizationGuard();

	const logout = useAuthStore((s) => s.logout);
	const companyId = useOrganizationStore((s) => s.companyId);
	const { data: org } = useOrganization(companyId);
	const { data: outlets, isLoading, isError } = useOutlets(companyId);

	const [createOpen, setCreateOpen] = useState(false);

	const handleLogout = () => {
		logout();
	};

	return (
		<AppLayout
			orgName={org?.name}
			isOrgActive={org?.is_active}
			onLogout={handleLogout}
		>
			<Box sx={{ p: { xs: 2.5, md: 4 } }}>
				{/* Шапка */}
				<Box
					sx={{
						display: 'flex',
						alignItems: { sm: 'center' },
						flexDirection: { xs: 'column', sm: 'row' },
						gap: 2,
						mb: 4,
					}}
				>
					<Box sx={{ flex: 1 }}>
						<Typography
							variant='h5'
							fontWeight={700}
							color='text.primary'
							letterSpacing='-0.02em'
							mb={0.5}
						>
							Точки продаж
						</Typography>
						<Typography variant='body2' color='text.secondary'>
							Адреса, часы работы и условия доставки
						</Typography>
					</Box>
					<Button
						variant='contained'
						startIcon={<AddIcon />}
						onClick={() => setCreateOpen(true)}
						sx={{ fontWeight: 600, flexShrink: 0 }}
					>
						Добавить точку
					</Button>
				</Box>

				{/* Карта точек */}
				{!isLoading && !isError && (outlets?.length ?? 0) > 0 && (
					<OutletsMap outlets={outlets!} />
				)}

				{/* Загрузка */}
				{isLoading && (
					<Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
						<CircularProgress />
					</Box>
				)}

				{/* Ошибка */}
				{isError && (
					<Alert severity='error' sx={{ borderRadius: 2 }}>
						Не удалось загрузить точки продаж. Попробуйте обновить страницу.
					</Alert>
				)}

				{/* Пустое состояние */}
				{!isLoading && !isError && (outlets?.length ?? 0) === 0 && (
					<Box
						sx={{
							display: 'flex',
							flexDirection: 'column',
							alignItems: 'center',
							py: 10,
							gap: 1.5,
						}}
					>
						<Box
							sx={{
								width: 72,
								height: 72,
								borderRadius: 3,
								bgcolor: 'rgba(74, 222, 128, 0.1)',
								display: 'flex',
								alignItems: 'center',
								justifyContent: 'center',
								mb: 1,
							}}
						>
							<StorefrontOutlinedIcon
								sx={{ fontSize: 32, color: 'primary.main' }}
							/>
						</Box>
						<Typography variant='h6' fontWeight={600} color='text.primary'>
							Нет точек продаж
						</Typography>
						<Typography
							variant='body2'
							color='text.secondary'
							textAlign='center'
						>
							Добавьте первую точку чтобы начать принимать заказы
						</Typography>
						<Button
							variant='contained'
							startIcon={<AddIcon />}
							onClick={() => setCreateOpen(true)}
							sx={{ mt: 1, fontWeight: 600 }}
						>
							Добавить точку
						</Button>
					</Box>
				)}

				{/* Сетка точек */}
				{!isLoading && (outlets?.length ?? 0) > 0 && (
					<Box
						sx={{
							display: 'grid',
							gridTemplateColumns: {
								xs: '1fr',
								sm: '1fr 1fr',
								lg: '1fr 1fr 1fr',
							},
							gap: 2.5,
						}}
					>
						{outlets!.map((outlet) => (
							<OutletCard
								key={outlet.id}
								outlet={outlet}
								companyId={companyId!}
							/>
						))}
					</Box>
				)}
			</Box>

			{/* Диалог создания точки */}
			{companyId && (
				<OutletDialog
					open={createOpen}
					onClose={() => setCreateOpen(false)}
					companyId={companyId}
				/>
			)}
		</AppLayout>
	);
}
