import { useState } from 'react';
import {
	Box,
	Typography,
	Button,
	CircularProgress,
	Alert,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import MenuBookOutlinedIcon from '@mui/icons-material/MenuBookOutlined';
import { useNavigate } from 'react-router';
import { useAuthGuard, useAuthStore } from '@features/auth';
import {
	useOrganizationGuard,
	useOrganizationStore,
	useOrganization,
} from '@features/organization';
import { useMenu, CategorySection, MenuItemDialog } from '@features/menu';
import type { MenuItem } from '@features/menu';
import { AppLayout } from '../layouts/AppLayout';

export default function MenuPage() {
	useAuthGuard();
	useOrganizationGuard();

	const navigate = useNavigate();
	const logout = useAuthStore((s) => s.logout);
	const companyId = useOrganizationStore((s) => s.companyId);
	const { data: org } = useOrganization(companyId);
	const { data: menu, isLoading, isError } = useMenu(companyId);

	const [editItem, setEditItem] = useState<MenuItem | null>(null);
	const [addItemCategoryId, setAddItemCategoryId] = useState<number | null>(null);
	const [addItemOpen, setAddItemOpen] = useState(false);

	const handleLogout = () => {
		logout();
		void navigate('/auth', { replace: true });
	};

	const categories = menu?.categories ?? [];
	const isDialogOpen = addItemOpen || addItemCategoryId !== null || editItem !== null;

	const handleCloseDialog = () => {
		setAddItemOpen(false);
		setAddItemCategoryId(null);
		setEditItem(null);
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
							Меню
						</Typography>
						<Typography variant='body2' color='text.secondary'>
							Управляйте позициями каталога
						</Typography>
					</Box>
					<Button
						variant='contained'
						startIcon={<AddIcon />}
						onClick={() => setAddItemOpen(true)}
						sx={{ fontWeight: 600, flexShrink: 0 }}
					>
						Добавить позицию
					</Button>
				</Box>

				{isLoading && (
					<Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
						<CircularProgress />
					</Box>
				)}

				{isError && (
					<Alert severity='error' sx={{ borderRadius: 2 }}>
						Не удалось загрузить меню. Попробуйте обновить страницу.
					</Alert>
				)}

				{!isLoading && !isError && categories.length === 0 && (
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
							<MenuBookOutlinedIcon
								sx={{ fontSize: 32, color: 'primary.main' }}
							/>
						</Box>
						<Typography variant='h6' fontWeight={600} color='text.primary'>
							Меню пока пустое
						</Typography>
						<Typography
							variant='body2'
							color='text.secondary'
							textAlign='center'
						>
							Добавьте первую позицию и она появится в каталоге
						</Typography>
						<Button
							variant='contained'
							startIcon={<AddIcon />}
							onClick={() => setAddItemOpen(true)}
							sx={{ mt: 1, fontWeight: 600 }}
						>
							Добавить позицию
						</Button>
					</Box>
				)}

				{!isLoading && categories.length > 0 && (
					<Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
						{categories.map((category) => (
							<CategorySection
								key={category.id}
								category={category}
								companyId={companyId!}
								onAddItem={(categoryId) => setAddItemCategoryId(categoryId)}
								onEditItem={(item) => setEditItem(item)}
							/>
						))}
					</Box>
				)}
			</Box>

			{companyId && isDialogOpen && (
				<MenuItemDialog
					open={isDialogOpen}
					onClose={handleCloseDialog}
					companyId={companyId}
					item={editItem ?? undefined}
					defaultCategoryId={addItemCategoryId ?? undefined}
				/>
			)}
		</AppLayout>
	);
}
