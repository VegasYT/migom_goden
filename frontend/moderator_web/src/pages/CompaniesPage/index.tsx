import { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router';
import {
	Box,
	Typography,
	CircularProgress,
	Alert,
	TablePagination,
	Paper,
	TextField,
	InputAdornment,
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import { useAuthGuard, useAuthStore } from '@features/auth';
import {
	useCompanies,
	useBlockCompany,
	useDeleteCompany,
	CompaniesTable,
	BlockCompanyDialog,
	DeleteCompanyDialog,
} from '@features/companies';
import type { Company } from '@features/companies';
import { AppLayout } from '@pages/layouts/AppLayout';
import { useDebouncedValue } from '@shared/lib/useDebouncedValue';

const DEFAULT_LIMIT = 20;

export default function CompaniesPage() {
	const { isAuthenticated } = useAuthGuard();
	const navigate = useNavigate();
	const logout = useAuthStore((s) => s.logout);

	const [searchParams, setSearchParams] = useSearchParams();
	const page = Number(searchParams.get('page') ?? '0');
	const limit = Number(searchParams.get('limit') ?? String(DEFAULT_LIMIT));

	const [search, setSearch] = useState('');
	const debouncedSearch = useDebouncedValue(search);

	const { data, isLoading, error } = useCompanies({
		offset: page * limit,
		limit,
		search: debouncedSearch || undefined,
	});

	const blockMutation = useBlockCompany();
	const deleteMutation = useDeleteCompany();

	const [blockTarget, setBlockTarget] = useState<Company | null>(null);
	const [deleteTarget, setDeleteTarget] = useState<Company | null>(null);

	const handlePageChange = (_: unknown, newPage: number) => {
		setSearchParams({ page: String(newPage), limit: String(limit) });
	};

	const handleRowsPerPageChange = (
		e: React.ChangeEvent<HTMLInputElement>
	) => {
		setSearchParams({ page: '0', limit: e.target.value });
	};

	const handleBlock = () => {
		if (!blockTarget) return;
		blockMutation.mutate(
			{ id: blockTarget.id, blocked: blockTarget.is_blocked },
			{ onSuccess: () => setBlockTarget(null) }
		);
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
				<Typography variant='h5' fontWeight={700} sx={{ mb: 0.5 }}>
					Предприятия
				</Typography>
				<Typography
					variant='body2'
					color='text.secondary'
					sx={{ mb: 3 }}
				>
					Просмотр и модерация предприятий платформы
				</Typography>

				<TextField
					placeholder='Поиск по названию...'
					value={search}
					onChange={(e) => {
						setSearch(e.target.value);
						setSearchParams({ page: '0', limit: String(limit) });
					}}
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
						Не удалось загрузить список предприятий
					</Alert>
				)}

				{data && (
					<Paper variant='outlined'>
						{data.items.length === 0 ? (
							<Typography
								variant='body2'
								color='text.secondary'
								sx={{ p: 4, textAlign: 'center' }}
							>
								Предприятия не найдены
							</Typography>
						) : (
							<>
								<CompaniesTable
									companies={data.items}
									onView={(c) =>
										void navigate(`/companies/${c.id}`)
									}
									onBlock={setBlockTarget}
									onDelete={setDeleteTarget}
								/>
								<TablePagination
									component='div'
									count={data.total}
									page={page}
									onPageChange={handlePageChange}
									rowsPerPage={limit}
									onRowsPerPageChange={handleRowsPerPageChange}
									rowsPerPageOptions={[10, 20, 50]}
									labelRowsPerPage='На странице:'
									labelDisplayedRows={({ from, to, count }) =>
										`${from}–${to} из ${count}`
									}
								/>
							</>
						)}
					</Paper>
				)}
			</Box>

			<BlockCompanyDialog
				open={blockTarget !== null}
				onClose={() => setBlockTarget(null)}
				company={blockTarget}
				onConfirm={handleBlock}
				isPending={blockMutation.isPending}
			/>

			<DeleteCompanyDialog
				open={deleteTarget !== null}
				onClose={() => setDeleteTarget(null)}
				company={deleteTarget}
				onConfirm={handleDelete}
				isPending={deleteMutation.isPending}
			/>
		</AppLayout>
	);
}
