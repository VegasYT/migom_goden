import { useState, useMemo } from 'react';
import { useSearchParams } from 'react-router';
import {
	Box,
	Typography,
	CircularProgress,
	Alert,
	Paper,
	Table,
	TableHead,
	TableBody,
	TableRow,
	TableCell,
	TablePagination,
} from '@mui/material';
import { useQueries } from '@tanstack/react-query';
import { useAuthGuard, useAuthStore } from '@features/auth';
import {
	useOrders,
	useCouriers,
	useAssignCourier,
	useCancelOrder,
	OrderFilters,
	OrderRow,
	AssignCourierDialog,
	CancelOrderDialog,
} from '@features/orders';
import type { Order, OrderStatus, SortField, SortOrder } from '@features/orders';
import {
	useCompanies,
	companiesKeys,
	companiesApi,
} from '@features/companies';
import type { Outlet } from '@features/companies';
import { AppLayout } from '@pages/layouts/AppLayout';
import { useDebouncedValue } from '@shared/lib/useDebouncedValue';

const DEFAULT_LIMIT = 20;

export default function OrdersPage() {
	const { isAuthenticated } = useAuthGuard();
	const logout = useAuthStore((s) => s.logout);

	const [searchParams, setSearchParams] = useSearchParams();
	const page = Number(searchParams.get('page') ?? '0');
	const limit = Number(searchParams.get('limit') ?? String(DEFAULT_LIMIT));

	const [search, setSearch] = useState('');
	const debouncedSearch = useDebouncedValue(search);
	const [status, setStatus] = useState<OrderStatus | ''>('');
	const [dateFrom, setDateFrom] = useState('');
	const [dateTo, setDateTo] = useState('');
	const [sortBy, setSortBy] = useState<SortField>('created_at');
	const [sortOrder, setSortOrder] = useState<SortOrder>('desc');

	const [selectedCompanyIds, setSelectedCompanyIds] = useState<number[]>([]);
	const [selectedOutletIds, setSelectedOutletIds] = useState<number[]>([]);

	const { data: companiesData } = useCompanies({ limit: 100 });

	const outletQueries = useQueries({
		queries: selectedCompanyIds.map((companyId) => ({
			queryKey: companiesKeys.outlets(companyId),
			queryFn: () => companiesApi.getOutlets(companyId),
		})),
	});

	const outletsLoading = outletQueries.some((q) => q.isLoading);
	const allOutlets = useMemo<Outlet[]>(
		() => outletQueries.flatMap((q) => q.data ?? []),
		[outletQueries]
	);

	const handleCompaniesChange = (ids: number[]) => {
		setSelectedCompanyIds(ids);
		setSelectedOutletIds([]);
		resetPage();
	};

	const handleOutletsChange = (ids: number[]) => {
		setSelectedOutletIds(ids);
		resetPage();
	};

	const { data, isLoading, error } = useOrders({
		offset: page * limit,
		limit,
		search: debouncedSearch || undefined,
		status: status || undefined,
		outlet_ids:
			selectedOutletIds.length > 0 ? selectedOutletIds : undefined,
		date_from: dateFrom || undefined,
		date_to: dateTo || undefined,
		sort_by: sortBy,
		sort_order: sortOrder,
	});

	const { data: couriersData, isLoading: couriersLoading } = useCouriers();
	const assignMutation = useAssignCourier();
	const cancelMutation = useCancelOrder();

	const [assignTarget, setAssignTarget] = useState<Order | null>(null);
	const [cancelTarget, setCancelTarget] = useState<Order | null>(null);

	const resetPage = () =>
		setSearchParams({ page: '0', limit: String(limit) });

	const handlePageChange = (_: unknown, newPage: number) => {
		setSearchParams({ page: String(newPage), limit: String(limit) });
	};

	const handleRowsPerPageChange = (
		e: React.ChangeEvent<HTMLInputElement>
	) => {
		setSearchParams({ page: '0', limit: e.target.value });
	};

	const handleAssign = (courierId: number) => {
		if (!assignTarget) return;
		assignMutation.mutate(
			{ orderId: assignTarget.id, courierId },
			{ onSuccess: () => setAssignTarget(null) }
		);
	};

	const handleCancel = () => {
		if (!cancelTarget) return;
		cancelMutation.mutate(cancelTarget.id, {
			onSuccess: () => setCancelTarget(null),
		});
	};

	if (!isAuthenticated) return null;

	return (
		<AppLayout onLogout={logout}>
			<Box sx={{ p: { xs: 2, md: 4 } }}>
				<Typography variant='h5' fontWeight={700} sx={{ mb: 0.5 }}>
					Заказы
				</Typography>
				<Typography
					variant='body2'
					color='text.secondary'
					sx={{ mb: 3 }}
				>
					Просмотр и управление заказами платформы
				</Typography>

				<OrderFilters
					search={search}
					status={status}
					dateFrom={dateFrom}
					dateTo={dateTo}
					sortBy={sortBy}
					sortOrder={sortOrder}
					companies={companiesData?.items ?? []}
					selectedCompanyIds={selectedCompanyIds}
					outlets={allOutlets}
					outletsLoading={outletsLoading}
					selectedOutletIds={selectedOutletIds}
					onSearchChange={(v) => {
						setSearch(v);
						resetPage();
					}}
					onStatusChange={(v) => {
						setStatus(v);
						resetPage();
					}}
					onDateFromChange={(v) => {
						setDateFrom(v);
						resetPage();
					}}
					onDateToChange={(v) => {
						setDateTo(v);
						resetPage();
					}}
					onSortByChange={setSortBy}
					onSortOrderChange={setSortOrder}
					onCompaniesChange={handleCompaniesChange}
					onOutletsChange={handleOutletsChange}
				/>

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
						Не удалось загрузить заказы
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
								Заказы не найдены
							</Typography>
						) : (
							<>
								<Table>
									<TableHead>
										<TableRow>
											<TableCell sx={{ width: 40 }} />
											<TableCell>ID</TableCell>
											<TableCell>Статус</TableCell>
											<TableCell>Тип</TableCell>
											<TableCell>Позиции</TableCell>
											<TableCell align='right'>
												Сумма
											</TableCell>
											<TableCell>Дата</TableCell>
											<TableCell align='right'>
												Действия
											</TableCell>
										</TableRow>
									</TableHead>
									<TableBody>
										{data.items.map((order) => (
											<OrderRow
												key={order.id}
												order={order}
												onAssign={setAssignTarget}
												onCancel={setCancelTarget}
											/>
										))}
									</TableBody>
								</Table>
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

			<AssignCourierDialog
				open={assignTarget !== null}
				onClose={() => setAssignTarget(null)}
				order={assignTarget}
				couriers={couriersData?.items ?? []}
				couriersLoading={couriersLoading}
				onAssign={handleAssign}
				isPending={assignMutation.isPending}
			/>

			<CancelOrderDialog
				open={cancelTarget !== null}
				onClose={() => setCancelTarget(null)}
				order={cancelTarget}
				onConfirm={handleCancel}
				isPending={cancelMutation.isPending}
			/>
		</AppLayout>
	);
}
