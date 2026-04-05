import { useState, useMemo } from 'react';
import { useSearchParams } from 'react-router';
import {
	Box,
	Typography,
	CircularProgress,
	Alert,
	Paper,
	TablePagination,
} from '@mui/material';
import { useAuthGuard, useAuthStore } from '@features/auth';
import {
	useCouriersList,
	useBlockCourier,
	useActiveShifts,
	CouriersTable,
	BlockCourierDialog,
} from '@features/couriers';
import type { Courier, Shift } from '@features/couriers';
import { AppLayout } from '@pages/layouts/AppLayout';

const DEFAULT_LIMIT = 20;

export default function CouriersPage() {
	const { isAuthenticated } = useAuthGuard();
	const logout = useAuthStore((s) => s.logout);

	const [searchParams, setSearchParams] = useSearchParams();
	const page = Number(searchParams.get('page') ?? '0');
	const limit = Number(searchParams.get('limit') ?? String(DEFAULT_LIMIT));

	const { data, isLoading, error } = useCouriersList({
		offset: page * limit,
		limit,
	});

	const { data: shiftsData } = useActiveShifts();
	const shiftsMap = useMemo(() => {
		const map = new Map<number, Shift>();
		for (const shift of shiftsData?.items ?? []) {
			map.set(shift.courier_id, shift);
		}
		return map;
	}, [shiftsData]);

	const blockMutation = useBlockCourier();
	const [blockTarget, setBlockTarget] = useState<Courier | null>(null);

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

	if (!isAuthenticated) return null;

	return (
		<AppLayout onLogout={logout}>
			<Box sx={{ p: { xs: 2, md: 4 } }}>
				<Typography variant='h5' fontWeight={700} sx={{ mb: 0.5 }}>
					Курьеры
				</Typography>
				<Typography
					variant='body2'
					color='text.secondary'
					sx={{ mb: 3 }}
				>
					Модерация курьеров платформы
				</Typography>

				{isLoading && (
					<Box
						sx={{
							display: 'flex',
							justifyContent: 'center',
							py: 8,
						}}
					>
						<CircularProgress />
					</Box>
				)}

				{error && (
					<Alert severity='error' sx={{ mb: 2 }}>
						Не удалось загрузить курьеров
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
								Курьеры не найдены
							</Typography>
						) : (
							<>
								<CouriersTable
									couriers={data.items}
									shifts={shiftsMap}
									onToggleBlock={setBlockTarget}
									blockPending={blockMutation.isPending}
								/>
								<TablePagination
									component='div'
									count={data.total}
									page={page}
									onPageChange={handlePageChange}
									rowsPerPage={limit}
									onRowsPerPageChange={
										handleRowsPerPageChange
									}
									rowsPerPageOptions={[10, 20, 50]}
									labelRowsPerPage='На странице:'
									labelDisplayedRows={({
										from,
										to,
										count,
									}) => `${from}–${to} из ${count}`}
								/>
							</>
						)}
					</Paper>
				)}
			</Box>

			<BlockCourierDialog
				open={blockTarget !== null}
				onClose={() => setBlockTarget(null)}
				courier={blockTarget}
				onConfirm={handleBlock}
				isPending={blockMutation.isPending}
			/>
		</AppLayout>
	);
}
