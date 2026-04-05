import {
	Box,
	Typography,
	Paper,
	Grid,
	CircularProgress,
	Table,
	TableHead,
	TableBody,
	TableRow,
	TableCell,
	Chip,
	Skeleton,
} from '@mui/material';
import BusinessOutlinedIcon from '@mui/icons-material/BusinessOutlined';
import CategoryOutlinedIcon from '@mui/icons-material/CategoryOutlined';
import ReceiptLongOutlinedIcon from '@mui/icons-material/ReceiptLongOutlined';
import DeliveryDiningOutlinedIcon from '@mui/icons-material/DeliveryDiningOutlined';
import { useNavigate } from 'react-router';
import type { ElementType } from 'react';
import { useAuthGuard, useAuthStore } from '@features/auth';
import { useCompanies } from '@features/companies';
import { useCategories } from '@features/categories';
import { useOrders, ORDER_STATUS_LABEL, ORDER_STATUS_COLOR } from '@features/orders';
import { useCouriersList } from '@features/couriers';
import { AppLayout } from '@pages/layouts/AppLayout';

function formatDate(iso: string) {
	return new Date(iso).toLocaleString('ru-RU', {
		day: '2-digit',
		month: '2-digit',
		hour: '2-digit',
		minute: '2-digit',
	});
}

interface StatCardProps {
	title: string;
	value: number | undefined;
	subtitle?: string;
	icon: ElementType;
	color: string;
	onClick?: () => void;
}

function StatCard({
	title,
	value,
	subtitle,
	icon: Icon,
	color,
	onClick,
}: StatCardProps) {
	return (
		<Paper
			variant='outlined'
			onClick={onClick}
			sx={{
				p: 2.5,
				cursor: onClick ? 'pointer' : 'default',
				transition: 'box-shadow 0.2s',
				'&:hover': onClick
					? { boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }
					: undefined,
			}}
		>
			<Box
				sx={{
					display: 'flex',
					alignItems: 'flex-start',
					justifyContent: 'space-between',
				}}
			>
				<Box>
					<Typography
						variant='caption'
						color='text.secondary'
						fontWeight={500}
					>
						{title}
					</Typography>
					{value !== undefined ? (
						<Typography variant='h4' fontWeight={700} sx={{ mt: 0.5 }}>
							{value}
						</Typography>
					) : (
						<Skeleton width={60} height={42} sx={{ mt: 0.5 }} />
					)}
					{subtitle && (
						<Typography
							variant='caption'
							color='text.secondary'
							sx={{ mt: 0.5, display: 'block' }}
						>
							{subtitle}
						</Typography>
					)}
				</Box>
				<Box
					sx={{
						width: 40,
						height: 40,
						borderRadius: 2,
						bgcolor: `${color}14`,
						display: 'flex',
						alignItems: 'center',
						justifyContent: 'center',
						flexShrink: 0,
					}}
				>
					<Icon sx={{ color, fontSize: 22 }} />
				</Box>
			</Box>
		</Paper>
	);
}

export default function DashboardPage() {
	const { isAuthenticated } = useAuthGuard();
	const logout = useAuthStore((s) => s.logout);
	const navigate = useNavigate();

	const { data: companiesData } = useCompanies({ limit: 1 });
	const { data: categoriesData } = useCategories();
	const { data: ordersData } = useOrders({
		limit: 7,
		sort_by: 'created_at',
		sort_order: 'desc',
	});
	const { data: couriersData } = useCouriersList({ limit: 1 });

	if (!isAuthenticated) return null;

	return (
		<AppLayout onLogout={logout}>
			<Box sx={{ p: { xs: 2, md: 4 } }}>
				<Typography variant='h5' fontWeight={700} sx={{ mb: 0.5 }}>
					Обзор
				</Typography>
				<Typography
					variant='body2'
					color='text.secondary'
					sx={{ mb: 3 }}
				>
					Панель модератора Мигом!
				</Typography>

				<Grid container spacing={2} sx={{ mb: 4 }}>
					<Grid size={{ xs: 6, md: 3 }}>
						<StatCard
							title='Предприятия'
							value={companiesData?.total}
							icon={BusinessOutlinedIcon}
							color='#2196f3'
							onClick={() => void navigate('/companies')}
						/>
					</Grid>
					<Grid size={{ xs: 6, md: 3 }}>
						<StatCard
							title='Категории'
							value={categoriesData?.length}
							icon={CategoryOutlinedIcon}
							color='#9c27b0'
							onClick={() => void navigate('/categories')}
						/>
					</Grid>
					<Grid size={{ xs: 6, md: 3 }}>
						<StatCard
							title='Заказы'
							value={ordersData?.total}
							icon={ReceiptLongOutlinedIcon}
							color='#ff9800'
							onClick={() => void navigate('/orders')}
						/>
					</Grid>
					<Grid size={{ xs: 6, md: 3 }}>
						<StatCard
							title='Курьеры'
							value={couriersData?.total}
							icon={DeliveryDiningOutlinedIcon}
							color='#4caf50'
							onClick={() => void navigate('/couriers')}
						/>
					</Grid>
				</Grid>

				<Typography
					variant='subtitle1'
					fontWeight={600}
					sx={{ mb: 1.5 }}
				>
					Последние заказы
				</Typography>

				<Paper variant='outlined'>
					{!ordersData ? (
						<Box
							sx={{
								display: 'flex',
								justifyContent: 'center',
								py: 4,
							}}
						>
							<CircularProgress size={24} />
						</Box>
					) : ordersData.items.length === 0 ? (
						<Typography
							variant='body2'
							color='text.secondary'
							sx={{ p: 4, textAlign: 'center' }}
						>
							Заказов пока нет
						</Typography>
					) : (
						<Table>
							<TableHead>
								<TableRow>
									<TableCell>ID</TableCell>
									<TableCell>Статус</TableCell>
									<TableCell>Позиции</TableCell>
									<TableCell align='right'>Сумма</TableCell>
									<TableCell>Дата</TableCell>
								</TableRow>
							</TableHead>
							<TableBody>
								{ordersData.items.map((order) => (
									<TableRow
										key={order.id}
										hover
										sx={{ cursor: 'pointer' }}
										onClick={() =>
											void navigate('/orders')
										}
									>
										<TableCell>
											<Typography
												variant='body2'
												fontWeight={600}
											>
												#{order.id}
											</Typography>
										</TableCell>
										<TableCell>
											<Chip
												label={
													ORDER_STATUS_LABEL[
														order.status
													]
												}
												size='small'
												color={
													ORDER_STATUS_COLOR[
														order.status
													] as
														| 'info'
														| 'warning'
														| 'secondary'
														| 'primary'
														| 'success'
														| 'error'
												}
											/>
										</TableCell>
										<TableCell sx={{ maxWidth: 200 }}>
											<Typography
												variant='body2'
												color='text.secondary'
												noWrap
											>
												{order.items
													.map(
														(i) =>
															`${i.name} ×${i.quantity}`
													)
													.join(', ') || '-'}
											</Typography>
										</TableCell>
										<TableCell align='right'>
											<Typography
												variant='body2'
												fontWeight={600}
											>
												{Number(
													order.total_price
												).toLocaleString('ru-RU')}{' '}
												₽
											</Typography>
										</TableCell>
										<TableCell>
											<Typography
												variant='caption'
												color='text.secondary'
											>
												{formatDate(order.created_at)}
											</Typography>
										</TableCell>
									</TableRow>
								))}
							</TableBody>
						</Table>
					)}
				</Paper>
			</Box>
		</AppLayout>
	);
}
