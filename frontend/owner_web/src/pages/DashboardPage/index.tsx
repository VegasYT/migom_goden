import {
	Box,
	Typography,
	Chip,
	Table,
	TableBody,
	TableCell,
	TableContainer,
	TableHead,
	TableRow,
} from '@mui/material';
import type { ElementType } from 'react';
import MenuBookOutlinedIcon from '@mui/icons-material/MenuBookOutlined';
import StorefrontOutlinedIcon from '@mui/icons-material/StorefrontOutlined';
import ReceiptLongOutlinedIcon from '@mui/icons-material/ReceiptLongOutlined';
import AnalyticsOutlinedIcon from '@mui/icons-material/AnalyticsOutlined';
import NorthEastIcon from '@mui/icons-material/NorthEast';
import { useNavigate } from 'react-router';
import { useAuthGuard, useAuthStore } from '@features/auth';
import {
	useOrganizationGuard,
	useOrganizationStore,
	useOrganization,
} from '@features/organization';
import { useMenu } from '@features/menu';
import { OutletsMap, useOutlets } from '@features/outlets';
import { useOrders, OrderRow } from '@features/orders';
import { AppLayout } from '../layouts/AppLayout';

const FEATURES: {
	icon: ElementType;
	title: string;
	description: string;
	path: string;
}[] = [
	{
		icon: MenuBookOutlinedIcon,
		title: 'Меню',
		description: 'Управляйте категориями и позициями каталога',
		path: '/menu',
	},
	{
		icon: StorefrontOutlinedIcon,
		title: 'Точки продаж',
		description: 'Настройте адреса, часы работы и условия доставки',
		path: '/outlets',
	},
	{
		icon: ReceiptLongOutlinedIcon,
		title: 'Заказы',
		description: 'Просмотр и управление входящими заказами',
		path: '/orders',
	},
	{
		icon: AnalyticsOutlinedIcon,
		title: 'Аналитика',
		description: 'Просмотр и управление входящими заказами',
		path: '/analytics',
	},
];

// ─── Stat card ────────────────────────────────────────────────────────────────

function StatCard({
	icon: Icon,
	label,
	value,
}: {
	icon: ElementType;
	label: string;
	value: number;
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
				gap: 2.5,
			}}
		>
			<Box
				sx={{
					width: 52,
					height: 52,
					borderRadius: 2.5,
					bgcolor: 'rgba(74, 222, 128, 0.1)',
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'center',
					flexShrink: 0,
				}}
			>
				<Icon sx={{ color: 'primary.main', fontSize: 24 }} />
			</Box>
			<Box>
				<Typography
					variant='h4'
					fontWeight={700}
					color='text.primary'
					lineHeight={1.1}
					letterSpacing='-0.02em'
				>
					{value}
				</Typography>
				<Typography variant='body2' color='text.secondary' mt={0.5}>
					{label}
				</Typography>
			</Box>
		</Box>
	);
}

// ─── Feature card ─────────────────────────────────────────────────────────────

function FeatureCard({
	icon: Icon,
	title,
	description,
	path,
	onNavigate,
}: {
	icon: ElementType;
	title: string;
	description: string;
	path: string;
	onNavigate: (path: string) => void;
}) {
	return (
		<Box
			onClick={() => onNavigate(path)}
			sx={{
				bgcolor: 'background.paper',
				border: '1px solid',
				borderColor: 'divider',
				borderRadius: 3,
				p: 3,
				cursor: 'pointer',
				transition: 'all 0.2s ease',
				height: '100%',
				'&:hover': {
					borderColor: 'primary.main',
					boxShadow: '0 6px 24px rgba(74, 222, 128, 0.12)',
					transform: 'translateY(-2px)',
				},
			}}
		>
			<Box
				sx={{
					display: 'flex',
					alignItems: 'flex-start',
					justifyContent: 'space-between',
					mb: 2.5,
				}}
			>
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
					<Icon sx={{ color: 'primary.main', fontSize: 22 }} />
				</Box>
				<NorthEastIcon
					sx={{
						color: 'text.secondary',
						fontSize: 18,
						mt: 0.25,
						opacity: 0.6,
					}}
				/>
			</Box>

			<Typography
				variant='subtitle2'
				fontWeight={600}
				color='text.primary'
				mb={0.75}
				letterSpacing='-0.01em'
			>
				{title}
			</Typography>
			<Typography variant='body2' color='text.secondary' lineHeight={1.6}>
				{description}
			</Typography>
		</Box>
	);
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function DashboardPage() {
	useAuthGuard();
	useOrganizationGuard();

	const navigate = useNavigate();
	const logout = useAuthStore((s) => s.logout);
	const companyId = useOrganizationStore((s) => s.companyId);
	const { data: org } = useOrganization(companyId);
	const { data: menu } = useMenu(companyId);
	const { data: outlets } = useOutlets(companyId);
	const { data: recentOrders } = useOrders({
		limit: 5,
		sort_by: 'created_at',
		sort_order: 'desc',
	});

	const menuItemsCount =
		menu?.categories?.reduce((acc, cat) => acc + cat.items.length, 0) ?? 0;
	const outletsCount = outlets?.length ?? 0;

	const stats: { icon: ElementType; label: string; value: number }[] = [
		{
			icon: MenuBookOutlinedIcon,
			label: 'Позиций в меню',
			value: menuItemsCount,
		},
		{
			icon: StorefrontOutlinedIcon,
			label: 'Точек продаж',
			value: outletsCount,
		},
		{
			icon: ReceiptLongOutlinedIcon,
			label: 'Всего заказов',
			value: recentOrders?.total ?? 0,
		},
	];

	const handleLogout = () => {
		logout();
		void navigate('/auth', { replace: true });
	};

	const latestOrders = recentOrders?.items ?? [];

	return (
		<AppLayout
			orgName={org?.name}
			isOrgActive={org?.is_active}
			onLogout={handleLogout}
		>
			<Box sx={{ p: { xs: 2.5, md: 4 } }}>
				<Box mb={4}>
					<Typography
						variant='h5'
						fontWeight={700}
						color='text.primary'
						letterSpacing='-0.02em'
						mb={0.5}
					>
						Обзор
					</Typography>
					<Typography variant='body2' color='text.secondary'>
						Ключевые показатели и быстрый доступ к разделам
					</Typography>
				</Box>

				{/* Статистика */}
				<Box
					sx={{
						display: 'grid',
						gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr 1fr' },
						gap: 2.5,
						mb: 5,
					}}
				>
					{stats.map((stat) => (
						<StatCard
							key={stat.label}
							icon={stat.icon}
							label={stat.label}
							value={stat.value}
						/>
					))}
				</Box>

				{/* Разделы */}
				<Typography
					variant='overline'
					color='text.secondary'
					letterSpacing='0.1em'
					fontWeight={600}
					display='block'
					mb={2}
				>
					Разделы
				</Typography>

				<Box
					sx={{
						display: 'grid',
						gridTemplateColumns: {
							xs: '1fr',
							sm: '1fr 1fr',
							md: '1fr 1fr 1fr 1fr',
						},
						gap: 2.5,
					}}
				>
					{FEATURES.map((feature) => (
						<FeatureCard
							key={feature.title}
							{...feature}
							onNavigate={(path) => void navigate(path)}
						/>
					))}
				</Box>

				{/* Карта точек */}
				<Box sx={{ mt: 4 }}>
					<OutletsMap outlets={outlets ?? []} />
				</Box>

				{/* Последние заказы */}
				{latestOrders.length > 0 && (
					<Box sx={{ mt: 4 }}>
						<Box
							sx={{
								display: 'flex',
								alignItems: 'center',
								justifyContent: 'space-between',
								mb: 2,
							}}
						>
							<Typography
								variant='overline'
								color='text.secondary'
								letterSpacing='0.1em'
								fontWeight={600}
							>
								Последние заказы
							</Typography>
							<Chip
								label='Все заказы'
								size='small'
								clickable
								onClick={() => void navigate('/orders')}
								sx={{
									height: 22,
									fontSize: 11,
									bgcolor: 'action.selected',
									color: 'text.secondary',
									'&:hover': { color: 'primary.main' },
								}}
							/>
						</Box>
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
									</TableRow>
								</TableHead>
								<TableBody>
									{latestOrders.map((order) => (
										<OrderRow
											key={order.id}
											order={order}
											outlets={outlets}
											hideActions
										/>
									))}
								</TableBody>
							</Table>
						</TableContainer>
					</Box>
				)}
			</Box>
		</AppLayout>
	);
}
