import { useState } from 'react';
import {
	Box,
	Typography,
	CircularProgress,
	Alert,
	Paper,
	Button,
	TextField,
	InputAdornment,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import SearchIcon from '@mui/icons-material/Search';
import { useAuthGuard, useAuthStore } from '@features/auth';
import {
	useCategories,
	useCreateCategory,
	useUpdateCategory,
	useDeleteCategory,
	CategoriesTable,
	CategoryDialog,
	DeleteCategoryDialog,
} from '@features/categories';
import type { Category } from '@features/categories';
import { AppLayout } from '@pages/layouts/AppLayout';
import { useDebouncedValue } from '@shared/lib/useDebouncedValue';

export default function CategoriesPage() {
	const { isAuthenticated } = useAuthGuard();
	const logout = useAuthStore((s) => s.logout);

	const [search, setSearch] = useState('');
	const debouncedSearch = useDebouncedValue(search);

	const { data: categories, isLoading, error } = useCategories(debouncedSearch);

	const createMutation = useCreateCategory();
	const updateMutation = useUpdateCategory();
	const deleteMutation = useDeleteCategory();

	const [dialogOpen, setDialogOpen] = useState(false);
	const [editTarget, setEditTarget] = useState<Category | null>(null);
	const [deleteTarget, setDeleteTarget] = useState<Category | null>(null);

	const handleCreate = () => {
		setEditTarget(null);
		setDialogOpen(true);
	};

	const handleEdit = (category: Category) => {
		setEditTarget(category);
		setDialogOpen(true);
	};

	const handleDialogSubmit = (values: {
		name: string;
		emoji: string;
		sort_order: number;
	}) => {
		if (editTarget) {
			updateMutation.mutate(
				{ id: editTarget.id, dto: values },
				{ onSuccess: () => setDialogOpen(false) }
			);
		} else {
			createMutation.mutate(values, {
				onSuccess: () => setDialogOpen(false),
			});
		}
	};

	const handleToggleActive = (category: Category) => {
		updateMutation.mutate({
			id: category.id,
			dto: { is_active: !category.is_active },
		});
	};

	const handleDelete = () => {
		if (!deleteTarget) return;
		deleteMutation.mutate(deleteTarget.id, {
			onSuccess: () => setDeleteTarget(null),
		});
	};

	if (!isAuthenticated) return null;

	return (
		<AppLayout onLogout={logout}>
			<Box sx={{ p: { xs: 2, md: 4 } }}>
				<Box
					sx={{
						display: 'flex',
						justifyContent: 'space-between',
						alignItems: 'flex-start',
						mb: 3,
					}}
				>
					<Box>
						<Typography variant='h5' fontWeight={700} sx={{ mb: 0.5 }}>
							Категории
						</Typography>
						<Typography variant='body2' color='text.secondary'>
							Глобальные категории позиций меню
						</Typography>
					</Box>
					<Button
						variant='contained'
						startIcon={<AddIcon />}
						onClick={handleCreate}
					>
						Создать
					</Button>
				</Box>

				<TextField
					placeholder='Поиск по названию...'
					value={search}
					onChange={(e) => setSearch(e.target.value)}
					size='small'
					sx={{ mb: 2, maxWidth: 360 }}
					fullWidth
					slotProps={{
						input: {
							startAdornment: (
								<InputAdornment position='start'>
									<SearchIcon
										sx={{ fontSize: 20, color: 'text.secondary' }}
									/>
								</InputAdornment>
							),
						},
					}}
				/>

				{isLoading && (
					<Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
						<CircularProgress />
					</Box>
				)}

				{error && (
					<Alert severity='error' sx={{ mb: 2 }}>
						Не удалось загрузить категории
					</Alert>
				)}

				{categories && (
					<Paper variant='outlined'>
						{categories.length === 0 ? (
							<Typography
								variant='body2'
								color='text.secondary'
								sx={{ p: 4, textAlign: 'center' }}
							>
								Категории не созданы
							</Typography>
						) : (
							<CategoriesTable
								categories={categories}
								onEdit={handleEdit}
								onDelete={setDeleteTarget}
								onToggleActive={handleToggleActive}
								togglePending={updateMutation.isPending}
							/>
						)}
					</Paper>
				)}
			</Box>

			<CategoryDialog
				open={dialogOpen}
				onClose={() => setDialogOpen(false)}
				category={editTarget}
				onSubmit={handleDialogSubmit}
				isPending={createMutation.isPending || updateMutation.isPending}
			/>

			<DeleteCategoryDialog
				open={deleteTarget !== null}
				onClose={() => setDeleteTarget(null)}
				category={deleteTarget}
				onConfirm={handleDelete}
				isPending={deleteMutation.isPending}
			/>
		</AppLayout>
	);
}
