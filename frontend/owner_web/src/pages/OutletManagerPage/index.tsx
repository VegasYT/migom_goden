import { useState } from 'react';
import {
	Box,
	Typography,
	IconButton,
	CircularProgress,
	Alert,
	Table,
	TableBody,
	TableCell,
	TableContainer,
	TableHead,
	TableRow,
	TextField,
} from '@mui/material';
import TwoWheelerIcon from '@mui/icons-material/TwoWheeler';
import LogoutOutlinedIcon from '@mui/icons-material/LogoutOutlined';
import KeyboardArrowLeftIcon from '@mui/icons-material/KeyboardArrowLeft';
import KeyboardArrowRightIcon from '@mui/icons-material/KeyboardArrowRight';
import ReceiptLongOutlinedIcon from '@mui/icons-material/ReceiptLongOutlined';
import { useNavigate, useSearchParams } from 'react-router';
import { useOutletManagerGuard, useAuthStore } from '@features/auth';
import { useOrders, OrderRow, OrderFilters } from '@features/orders';
import type { OrderStatus, SortField, SortOrder } from '@features/orders';
import { ColorModeButton } from '@shared/ui/color-mode';
import { Toaster } from '@shared/ui/toaster';

const DEFAULT_LIMIT = 20;
const MIN_LIMIT = 10;
const MAX_LIMIT = 100;

function clampLimit(v: number) {
	if (isNaN(v) || v < MIN_LIMIT) return MIN_LIMIT;
	if (v > MAX_LIMIT) return MAX_LIMIT;
	return Math.floor(v);
}

export default function OutletManagerPage() {
	useOutletManagerGuard();

	const navigate = useNavigate();
	const logout = useAuthStore((s) => s.logout);
	const user = useAuthStore((s) => s.user);

	const [searchParams, setSearchParams] = useSearchParams();

	const status = (searchParams.get('status') ?? '') as OrderStatus | '';
	const dateFrom = searchParams.get('date_from') ?? '';
	const dateTo = searchParams.get('date_to') ?? '';
	const sortBy = (searchParams.get('sort_by') ?? 'created_at') as SortField;
	const sortOrder = (searchParams.get('sort_order') ?? 'desc') as SortOrder;
	const page = Number(searchParams.get('page') ?? '0');
	const limit = clampLimit(Number(searchParams.get('limit') ?? String(DEFAULT_LIMIT)));

	const [limitInput, setLimitInput] = useState(String(limit));

	const filter = {
		offset: page * limit,
		limit,
		...(status && { status }),
		...(dateFrom && { date_from: new Date(dateFrom).toISOString() }),
		...(dateTo && { date_to: new Date(dateTo + 'T23:59:59').toISOString() }),
		sort_by: sortBy,
		sort_order: sortOrder,
	};

	const { data, isLoading, isError } = useOrders(filter);

	const updateParam = (key: string, value: string) => {
		setSearchParams((prev) => {
			const next = new URLSearchParams(prev);
			if (value) {
				next.set(key, value);
			} else {
				next.delete(key);
			}
			if (key !== 'page') {
				next.delete('page');
			}
			return next;
		});
	};

	const commitLimit = () => {
		const clamped = clampLimit(Number(limitInput));
		setLimitInput(String(clamped));
		updateParam('limit', clamped === DEFAULT_LIMIT ? '' : String(clamped));
	};

	const handleLogout = () => {
		logout();
		void navigate('/auth', { replace: true });
	};

	const orders = data?.items ?? [];
	const total = data?.total ?? 0;
	const totalPages = Math.ceil(total / limit);

	return (
		<Box
			sx={{
				minHeight: '100vh',
				bgcolor: 'background.default',
				display: 'flex',
				flexDirection: 'column',
			}}
		>
			<Toaster />

			{/* Хедер */}
			<Box
				sx={{
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'space-between',
					px: 3,
					py: 2,
					borderBottom: '1px solid',
					borderColor: 'divider',
					bgcolor: 'background.paper',
				}}
			>
				<Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
					<Box
						sx={{
							width: 36,
							height: 36,
							borderRadius: 1.5,
							bgcolor: 'primary.main',
							display: 'flex',
							alignItems: 'center',
							justifyContent: 'center',
							boxShadow: '0 4px 12px rgba(74, 222, 128, 0.3)',
						}}
					>
						<TwoWheelerIcon sx={{ color: 'white', fontSize: 20 }} />
					</Box>
					<Typography variant='subtitle1' fontWeight={700} color='text.primary'>
						Мигом! Менеджер
					</Typography>
				</Box>

				<Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
					{user && (
						<Typography variant='body2' color='text.secondary'>
							{user.full_name}
						</Typography>
					)}
					<ColorModeButton sx={{ color: 'text.secondary' }} />
					<IconButton size='small' onClick={handleLogout} sx={{ color: 'error.main' }}>
						<LogoutOutlinedIcon fontSize='small' />
					</IconButton>
				</Box>
			</Box>

			{/* Контент */}
			<Box sx={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
				<Box sx={{ p: { xs: 2.5, md: 4 }, flex: 1 }}>
					{/* Шапка */}
					<Box sx={{ mb: 4 }}>
						<Typography
							variant='h5'
							fontWeight={700}
							color='text.primary'
							letterSpacing='-0.02em'
							mb={0.5}
						>
							Заказы точки
						</Typography>
						<Typography variant='body2' color='text.secondary'>
							Управляйте заказами вашей торговой точки
						</Typography>
					</Box>

					{/* Фильтры */}
					<OrderFilters
						status={status}
						dateFrom={dateFrom}
						dateTo={dateTo}
						sortBy={sortBy}
						sortOrder={sortOrder}
						onStatusChange={(v) => updateParam('status', v)}
						onDateFromChange={(v) => updateParam('date_from', v)}
						onDateToChange={(v) => updateParam('date_to', v)}
						onSortByChange={(v) => updateParam('sort_by', v === 'created_at' ? '' : v)}
						onSortOrderChange={(v) => updateParam('sort_order', v === 'desc' ? '' : v)}
					/>

					{/* Загрузка */}
					{isLoading && (
						<Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
							<CircularProgress />
						</Box>
					)}

					{/* Ошибка */}
					{isError && (
						<Alert severity='error' sx={{ borderRadius: 2 }}>
							Не удалось загрузить заказы. Попробуйте обновить страницу.
						</Alert>
					)}

					{/* Пустое состояние */}
					{!isLoading && !isError && orders.length === 0 && (
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
								<ReceiptLongOutlinedIcon sx={{ fontSize: 32, color: 'primary.main' }} />
							</Box>
							<Typography variant='h6' fontWeight={600} color='text.primary'>
								Заказов пока нет
							</Typography>
							<Typography variant='body2' color='text.secondary' textAlign='center'>
								{status
									? 'Нет заказов с выбранным фильтром'
									: 'Когда клиенты оформят заказ, он появится здесь'}
							</Typography>
						</Box>
					)}

					{/* Таблица */}
					{!isLoading && orders.length > 0 && (
						<TableContainer
							sx={{
								bgcolor: 'background.paper',
								border: '1px solid',
								borderColor: 'divider',
								borderRadius: 3,
								overflow: 'hidden',
							}}
						>
							<Table size='small'>
								<TableHead>
									<TableRow
										sx={{
											'& th': {
												fontWeight: 600,
												color: 'text.secondary',
												fontSize: 12,
												py: 1.5,
											},
										}}
									>
										<TableCell sx={{ width: 40 }} />
										<TableCell>№</TableCell>
										<TableCell>Статус</TableCell>
										<TableCell>Тип</TableCell>
										<TableCell>Позиции</TableCell>
										<TableCell align='right'>Сумма</TableCell>
										<TableCell>Дата</TableCell>
										<TableCell align='right'>Действия</TableCell>
									</TableRow>
								</TableHead>
								<TableBody>
									{orders.map((order) => (
										<OrderRow key={order.id} order={order} />
									))}
								</TableBody>
							</Table>
						</TableContainer>
					)}
				</Box>

				{/* Футер с пагинацией */}
				{!isLoading && total > 0 && (
					<Box
						sx={{
							position: 'sticky',
							bottom: 0,
							bgcolor: 'background.paper',
							borderTop: '1px solid',
							borderColor: 'divider',
							px: { xs: 2.5, md: 4 },
							py: 1.5,
							display: 'flex',
							alignItems: 'center',
							justifyContent: 'space-between',
							flexWrap: 'wrap',
							gap: 1.5,
							zIndex: 1,
						}}
					>
						<Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
							<Typography variant='body2' color='text.secondary'>
								Показывать:
							</Typography>
							<TextField
								size='small'
								value={limitInput}
								onChange={(e) => setLimitInput(e.target.value.replace(/[^0-9]/g, ''))}
								onBlur={commitLimit}
								onKeyDown={(e) => {
									if (e.key === 'Enter') commitLimit();
								}}
								slotProps={{
									htmlInput: {
										inputMode: 'numeric',
										min: MIN_LIMIT,
										max: MAX_LIMIT,
										style: { textAlign: 'center', width: 40, padding: '4px 8px' },
									},
								}}
								sx={{ width: 64 }}
							/>
							<Typography variant='caption' color='text.secondary'>
								({MIN_LIMIT}–{MAX_LIMIT})
							</Typography>
						</Box>

						<Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
							<Typography variant='body2' color='text.secondary'>
								{page * limit + 1}–{Math.min((page + 1) * limit, total)} из {total}
							</Typography>
							<IconButton
								size='small'
								disabled={page === 0}
								onClick={() => updateParam('page', page - 1 === 0 ? '' : String(page - 1))}
							>
								<KeyboardArrowLeftIcon fontSize='small' />
							</IconButton>
							<IconButton
								size='small'
								disabled={page + 1 >= totalPages}
								onClick={() => updateParam('page', String(page + 1))}
							>
								<KeyboardArrowRightIcon fontSize='small' />
							</IconButton>
						</Box>
					</Box>
				)}
			</Box>
		</Box>
	);
}
