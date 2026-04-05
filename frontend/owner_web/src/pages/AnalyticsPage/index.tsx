import {
	Box,
	Typography,
	CircularProgress,
	Alert,
	LinearProgress,
	Button,
	useTheme,
} from '@mui/material';
import FileDownloadOutlinedIcon from '@mui/icons-material/FileDownloadOutlined';
import AnalyticsOutlinedIcon from '@mui/icons-material/AnalyticsOutlined';
import TrendingUpOutlinedIcon from '@mui/icons-material/TrendingUpOutlined';
import ReceiptLongOutlinedIcon from '@mui/icons-material/ReceiptLongOutlined';
import ShoppingCartOutlinedIcon from '@mui/icons-material/ShoppingCartOutlined';
import MopedOutlinedIcon from '@mui/icons-material/MopedOutlined';
import ShoppingBagOutlinedIcon from '@mui/icons-material/ShoppingBagOutlined';
import CancelOutlinedIcon from '@mui/icons-material/CancelOutlined';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import type { ElementType } from 'react';
import { useNavigate } from 'react-router';
import { useAuthGuard, useAuthStore } from '@features/auth';
import {
	useOrganizationGuard,
	useOrganizationStore,
	useOrganization,
} from '@features/organization';
import { useOrders, ORDER_STATUS_LABEL, exportAnalyticsReport } from '@features/orders';
import type { Order, OrderStatus } from '@features/orders';
import { AppLayout } from '../layouts/AppLayout';

// ─── Утилиты ──────────────────────────────────────────────────────────────────

function computeStats(orders: Order[]) {
	const totalRevenue = orders.reduce((s, o) => s + Number(o.total_price), 0);
	const completed = orders.filter((o) => ['delivered', 'received'].includes(o.status));
	const completedRevenue = completed.reduce((s, o) => s + Number(o.total_price), 0);
	const avgOrderValue = completed.length > 0 ? completedRevenue / completed.length : 0;
	const cancelledCount = orders.filter((o) => o.status === 'cancelled').length;
	const cancelRate = orders.length > 0 ? (cancelledCount / orders.length) * 100 : 0;

	// По статусам
	const byStatus = new Map<OrderStatus, number>();
	for (const o of orders) {
		byStatus.set(o.status, (byStatus.get(o.status) ?? 0) + 1);
	}

	// По типу доставки
	const deliveryCount = orders.filter((o) => o.delivery_type === 'delivery').length;
	const pickupCount = orders.filter((o) => o.delivery_type === 'pickup').length;

	// Топ позиции
	const itemMap = new Map<string, { name: string; qty: number; revenue: number }>();
	for (const o of orders) {
		for (const item of o.items) {
			const existing = itemMap.get(item.name);
			if (existing) {
				existing.qty += item.quantity;
				existing.revenue += Number(item.subtotal);
			} else {
				itemMap.set(item.name, {
					name: item.name,
					qty: item.quantity,
					revenue: Number(item.subtotal),
				});
			}
		}
	}
	const topItems = [...itemMap.values()]
		.sort((a, b) => b.qty - a.qty)
		.slice(0, 8);

	// Выручка по дням (последние 7 дней)
	const dailyRevenue = new Map<string, number>();
	const now = new Date();
	for (let i = 6; i >= 0; i--) {
		const d = new Date(now);
		d.setDate(d.getDate() - i);
		dailyRevenue.set(d.toISOString().slice(0, 10), 0);
	}
	for (const o of completed) {
		const day = o.created_at.slice(0, 10);
		if (dailyRevenue.has(day)) {
			dailyRevenue.set(day, dailyRevenue.get(day)! + Number(o.total_price));
		}
	}
	const dailyData = [...dailyRevenue.entries()].map(([date, value]) => ({
		label: new Date(date).toLocaleDateString('ru-RU', { day: '2-digit', month: '2-digit' }),
		value,
	}));

	return {
		totalOrders: orders.length,
		totalRevenue,
		completedRevenue,
		avgOrderValue,
		cancelledCount,
		cancelRate,
		byStatus,
		deliveryCount,
		pickupCount,
		topItems,
		dailyData,
	};
}

// ─── Компоненты карточек ──────────────────────────────────────────────────────

function StatCard({
	icon: Icon,
	label,
	value,
	color = 'primary.main',
}: {
	icon: ElementType;
	label: string;
	value: string;
	color?: string;
}) {
	return (
		<Box
			sx={{
				bgcolor: 'background.paper',
				border: '1px solid',
				borderColor: 'divider',
				borderRadius: 3,
				p: 2.5,
				display: 'flex',
				alignItems: 'center',
				gap: 2,
			}}
		>
			<Box
				sx={{
					width: 48,
					height: 48,
					borderRadius: 2,
					bgcolor: 'rgba(74, 222, 128, 0.1)',
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'center',
					flexShrink: 0,
				}}
			>
				<Icon sx={{ color, fontSize: 22 }} />
			</Box>
			<Box>
				<Typography variant='h5' fontWeight={700} color='text.primary' lineHeight={1.2}>
					{value}
				</Typography>
				<Typography variant='caption' color='text.secondary'>
					{label}
				</Typography>
			</Box>
		</Box>
	);
}

function BarChart({ data, maxValue }: { data: { label: string; value: number }[]; maxValue: number }) {
	const theme = useTheme();
	return (
		<Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1, height: 140, mt: 1 }}>
			{data.map((d) => (
				<Box key={d.label} sx={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0.5 }}>
					<Typography variant='caption' color='text.secondary' sx={{ fontSize: 10 }}>
						{d.value > 0 ? `${(d.value / 1000).toFixed(1)}к` : ''}
					</Typography>
					<Box
						sx={{
							width: '100%',
							maxWidth: 40,
							height: maxValue > 0 ? Math.max((d.value / maxValue) * 100, 4) : 4,
							bgcolor: d.value > 0 ? theme.palette.primary.main : 'action.selected',
							borderRadius: 1,
							transition: 'height 0.3s ease',
						}}
					/>
					<Typography variant='caption' color='text.secondary' sx={{ fontSize: 10 }}>
						{d.label}
					</Typography>
				</Box>
			))}
		</Box>
	);
}

function StatusRow({ label, count, total, color }: { label: string; count: number; total: number; color: string }) {
	const pct = total > 0 ? (count / total) * 100 : 0;
	return (
		<Box sx={{ mb: 1.5 }}>
			<Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
				<Typography variant='body2' color='text.primary'>
					{label}
				</Typography>
				<Typography variant='body2' color='text.secondary'>
					{count} ({pct.toFixed(0)}%)
				</Typography>
			</Box>
			<LinearProgress
				variant='determinate'
				value={pct}
				sx={{
					height: 6,
					borderRadius: 3,
					bgcolor: 'action.hover',
					'& .MuiLinearProgress-bar': { bgcolor: color, borderRadius: 3 },
				}}
			/>
		</Box>
	);
}

// ─── Маппинг цветов статусов ──────────────────────────────────────────────────

const STATUS_BAR_COLORS: Record<string, string> = {
	new: '#29b6f6',
	assigned: '#ffa726',
	assembling: '#ffca28',
	ready_for_pickup: '#66bb6a',
	in_delivery: '#4ADE80',
	delivered: '#43a047',
	cancelled: '#ef5350',
	received: '#9e9e9e',
};

// ─── Страница ─────────────────────────────────────────────────────────────────

export default function AnalyticsPage() {
	useAuthGuard();
	useOrganizationGuard();

	const navigate = useNavigate();
	const logout = useAuthStore((s) => s.logout);
	const companyId = useOrganizationStore((s) => s.companyId);
	const { data: org } = useOrganization(companyId);

	// Загружаем побольше заказов для аналитики
	const { data, isLoading, isError } = useOrders({ limit: 100, sort_by: 'created_at', sort_order: 'desc' });

	const handleLogout = () => {
		logout();
		void navigate('/auth', { replace: true });
	};

	const orders = data?.items ?? [];
	const stats = computeStats(orders);
	const maxDaily = Math.max(...stats.dailyData.map((d) => d.value), 1);
	const maxItemQty = stats.topItems.length > 0 ? stats.topItems[0].qty : 1;

	return (
		<AppLayout orgName={org?.name} isOrgActive={org?.is_active} onLogout={handleLogout}>
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
							Аналитика
						</Typography>
						<Typography variant='body2' color='text.secondary'>
							Статистика по последним {orders.length} заказам
						</Typography>
					</Box>
					{orders.length > 0 && (
						<Button
							variant='outlined'
							startIcon={<FileDownloadOutlinedIcon />}
							onClick={() => exportAnalyticsReport(orders, org?.name)}
							sx={{ fontWeight: 600, flexShrink: 0, textTransform: 'none' }}
						>
							Скачать отчёт
						</Button>
					)}
				</Box>

				{isLoading && (
					<Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
						<CircularProgress />
					</Box>
				)}

				{isError && (
					<Alert severity='error' sx={{ borderRadius: 2 }}>
						Не удалось загрузить данные. Попробуйте обновить страницу.
					</Alert>
				)}

				{!isLoading && !isError && orders.length === 0 && (
					<Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 10, gap: 1.5 }}>
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
							<AnalyticsOutlinedIcon sx={{ fontSize: 32, color: 'primary.main' }} />
						</Box>
						<Typography variant='h6' fontWeight={600} color='text.primary'>
							Нет данных для аналитики
						</Typography>
						<Typography variant='body2' color='text.secondary'>
							Статистика появится когда будут оформлены первые заказы
						</Typography>
					</Box>
				)}

				{!isLoading && orders.length > 0 && (
					<>
						{/* Основные метрики */}
						<Box
							sx={{
								display: 'grid',
								gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', md: '1fr 1fr 1fr 1fr' },
								gap: 2.5,
								mb: 4,
							}}
						>
							<StatCard
								icon={ReceiptLongOutlinedIcon}
								label='Всего заказов'
								value={String(stats.totalOrders)}
							/>
							<StatCard
								icon={TrendingUpOutlinedIcon}
								label='Выручка (выполненные)'
								value={`${stats.completedRevenue.toLocaleString('ru-RU', { maximumFractionDigits: 0 })} ₽`}
							/>
							<StatCard
								icon={ShoppingCartOutlinedIcon}
								label='Средний чек'
								value={`${stats.avgOrderValue.toLocaleString('ru-RU', { maximumFractionDigits: 0 })} ₽`}
							/>
							<StatCard
								icon={CancelOutlinedIcon}
								label='Процент отмен'
								value={`${stats.cancelRate.toFixed(1)}%`}
								color='error.main'
							/>
						</Box>

						{/* Графики */}
						<Box
							sx={{
								display: 'grid',
								gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' },
								gap: 2.5,
								mb: 4,
							}}
						>
							{/* Выручка по дням */}
							<Box
								sx={{
									bgcolor: 'background.paper',
									border: '1px solid',
									borderColor: 'divider',
									borderRadius: 3,
									p: 2.5,
								}}
							>
								<Typography variant='subtitle2' fontWeight={600} color='text.primary' mb={1}>
									Выручка за 7 дней
								</Typography>
								<BarChart data={stats.dailyData} maxValue={maxDaily} />
							</Box>

							{/* Статусы заказов */}
							<Box
								sx={{
									bgcolor: 'background.paper',
									border: '1px solid',
									borderColor: 'divider',
									borderRadius: 3,
									p: 2.5,
								}}
							>
								<Typography variant='subtitle2' fontWeight={600} color='text.primary' mb={2}>
									Распределение по статусам
								</Typography>
								{([...stats.byStatus.entries()] as [OrderStatus, number][])
									.sort((a, b) => b[1] - a[1])
									.map(([status, count]) => (
										<StatusRow
											key={status}
											label={ORDER_STATUS_LABEL[status]}
											count={count}
											total={stats.totalOrders}
											color={STATUS_BAR_COLORS[status] ?? '#9e9e9e'}
										/>
									))}
							</Box>
						</Box>

						{/* Нижний ряд */}
						<Box
							sx={{
								display: 'grid',
								gridTemplateColumns: { xs: '1fr', md: '2fr 1fr' },
								gap: 2.5,
							}}
						>
							{/* Топ позиций */}
							<Box
								sx={{
									bgcolor: 'background.paper',
									border: '1px solid',
									borderColor: 'divider',
									borderRadius: 3,
									p: 2.5,
								}}
							>
								<Typography variant='subtitle2' fontWeight={600} color='text.primary' mb={2}>
									Популярные позиции
								</Typography>
								{stats.topItems.map((item, i) => (
									<Box key={item.name} sx={{ mb: 1.5 }}>
										<Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
											<Typography variant='body2' color='text.primary' noWrap sx={{ flex: 1, mr: 2 }}>
												{i + 1}. {item.name}
											</Typography>
											<Typography variant='body2' color='text.secondary' sx={{ flexShrink: 0 }}>
												{item.qty} шт · {item.revenue.toLocaleString('ru-RU', { maximumFractionDigits: 0 })} ₽
											</Typography>
										</Box>
										<LinearProgress
											variant='determinate'
											value={(item.qty / maxItemQty) * 100}
											sx={{
												height: 6,
												borderRadius: 3,
												bgcolor: 'action.hover',
												'& .MuiLinearProgress-bar': { bgcolor: 'primary.main', borderRadius: 3 },
											}}
										/>
									</Box>
								))}
								{stats.topItems.length === 0 && (
									<Typography variant='body2' color='text.secondary'>
										Нет данных
									</Typography>
								)}
							</Box>

							{/* Тип доставки */}
							<Box
								sx={{
									bgcolor: 'background.paper',
									border: '1px solid',
									borderColor: 'divider',
									borderRadius: 3,
									p: 2.5,
									display: 'flex',
									flexDirection: 'column',
								}}
							>
								<Typography variant='subtitle2' fontWeight={600} color='text.primary' mb={3}>
									Способ получения
								</Typography>
								<Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 3 }}>
									<Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
										<Box
											sx={{
												width: 44,
												height: 44,
												borderRadius: 2,
												bgcolor: 'rgba(74, 222, 128, 0.1)',
												display: 'flex',
												alignItems: 'center',
												justifyContent: 'center',
											}}
										>
											<MopedOutlinedIcon sx={{ color: 'primary.main', fontSize: 22 }} />
										</Box>
										<Box sx={{ flex: 1 }}>
											<Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
												<Typography variant='body2'>Доставка</Typography>
												<Typography variant='body2' color='text.secondary'>
													{stats.deliveryCount}
												</Typography>
											</Box>
											<LinearProgress
												variant='determinate'
												value={stats.totalOrders > 0 ? (stats.deliveryCount / stats.totalOrders) * 100 : 0}
												sx={{
													height: 6,
													borderRadius: 3,
													bgcolor: 'action.hover',
													'& .MuiLinearProgress-bar': { bgcolor: 'primary.main', borderRadius: 3 },
												}}
											/>
										</Box>
									</Box>

									<Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
										<Box
											sx={{
												width: 44,
												height: 44,
												borderRadius: 2,
												bgcolor: 'rgba(74, 222, 128, 0.1)',
												display: 'flex',
												alignItems: 'center',
												justifyContent: 'center',
											}}
										>
											<ShoppingBagOutlinedIcon sx={{ color: 'primary.main', fontSize: 22 }} />
										</Box>
										<Box sx={{ flex: 1 }}>
											<Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
												<Typography variant='body2'>Самовывоз</Typography>
												<Typography variant='body2' color='text.secondary'>
													{stats.pickupCount}
												</Typography>
											</Box>
											<LinearProgress
												variant='determinate'
												value={stats.totalOrders > 0 ? (stats.pickupCount / stats.totalOrders) * 100 : 0}
												sx={{
													height: 6,
													borderRadius: 3,
													bgcolor: 'action.hover',
													'& .MuiLinearProgress-bar': {
														bgcolor: 'warning.main',
														borderRadius: 3,
													},
												}}
											/>
										</Box>
									</Box>

									{/* Итог */}
									<Box sx={{ textAlign: 'center', pt: 1, borderTop: '1px solid', borderColor: 'divider' }}>
										<Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0.5 }}>
											<CheckCircleOutlineIcon sx={{ fontSize: 14, color: 'success.main' }} />
											<Typography variant='caption' color='text.secondary'>
												Выполнено: {orders.filter((o) => ['delivered', 'received'].includes(o.status)).length} из {stats.totalOrders}
											</Typography>
										</Box>
									</Box>
								</Box>
							</Box>
						</Box>
					</>
				)}
			</Box>
		</AppLayout>
	);
}
