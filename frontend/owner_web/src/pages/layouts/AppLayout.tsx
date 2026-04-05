import { useState } from 'react';
import {
	Box,
	Drawer,
	Typography,
	IconButton,
	List,
	ListItemButton,
	ListItemIcon,
	ListItemText,
	Chip,
	Divider,
	BottomNavigation,
	BottomNavigationAction,
	Paper,
	useTheme,
	useMediaQuery,
	alpha,
	Tooltip,
} from '@mui/material';
import TwoWheelerIcon from '@mui/icons-material/TwoWheeler';
import DashboardOutlinedIcon from '@mui/icons-material/DashboardOutlined';
import MenuBookOutlinedIcon from '@mui/icons-material/MenuBookOutlined';
import StorefrontOutlinedIcon from '@mui/icons-material/StorefrontOutlined';
import ReceiptLongOutlinedIcon from '@mui/icons-material/ReceiptLongOutlined';
import AnalyticsOutlinedIcon from '@mui/icons-material/AnalyticsOutlined';
import LogoutOutlinedIcon from '@mui/icons-material/LogoutOutlined';
import MoreHorizIcon from '@mui/icons-material/MoreHoriz';
import SettingsOutlinedIcon from '@mui/icons-material/SettingsOutlined';
import AccountCircleOutlinedIcon from '@mui/icons-material/AccountCircleOutlined';
import { useLocation, useNavigate } from 'react-router';
import type { ElementType } from 'react';
import { ColorModeButton } from '@shared/ui/color-mode';
import { Toaster } from '@shared/ui/toaster';
import { useAuthStore } from '@features/auth';
import {
	useOrganizationStore,
	CompanySettingsDialog,
} from '@features/organization';

const DRAWER_WIDTH = 240;
const BOTTOM_NAV_HEIGHT = 56;

interface NavItemDef {
	label: string;
	icon: ElementType;
	path: string;
	disabled?: boolean;
	soon?: boolean;
}

const NAV_ITEMS: NavItemDef[] = [
	{ label: 'Обзор', icon: DashboardOutlinedIcon, path: '/' },
	{ label: 'Меню', icon: MenuBookOutlinedIcon, path: '/menu' },
	{ label: 'Точки продаж', icon: StorefrontOutlinedIcon, path: '/outlets' },
	{ label: 'Заказы', icon: ReceiptLongOutlinedIcon, path: '/orders' },
	{ label: 'Аналитика', icon: AnalyticsOutlinedIcon, path: '/analytics' },
];

export interface AppLayoutProps {
	children: React.ReactNode;
	orgName?: string;
	isOrgActive?: boolean;
	onLogout: () => void;
}

export function AppLayout({
	children,
	orgName,
	isOrgActive = true,
	onLogout,
}: AppLayoutProps) {
	const theme = useTheme();
	const isMobile = useMediaQuery(theme.breakpoints.down('md'));
	const [moreOpen, setMoreOpen] = useState(false);
	const [settingsOpen, setSettingsOpen] = useState(false);
	const location = useLocation();
	const navigate = useNavigate();

	const user = useAuthStore((s) => s.user);
	const companyId = useOrganizationStore((s) => s.companyId);
	const clearCompany = useOrganizationStore((s) => s.clearCompany);

	const activeNavIndex = NAV_ITEMS.findIndex(
		(item) => item.path === location.pathname
	);

	const handleCompanyDeleted = () => {
		setSettingsOpen(false);
		clearCompany();
		void navigate('/organization/new', { replace: true });
	};

	const orgBlock = (inSheet = false) =>
		orgName ? (
			<Box
				sx={{
					display: 'flex',
					alignItems: 'center',
					gap: 0.75,
					px: 1.5,
					py: inSheet ? 1.25 : 1,
					mb: inSheet ? 2 : 1.5,
					bgcolor: 'action.hover',
					borderRadius: 2,
					border: '1px solid',
					borderColor: 'divider',
				}}
			>
				<Box
					sx={{
						width: inSheet ? 8 : 7,
						height: inSheet ? 8 : 7,
						borderRadius: '50%',
						bgcolor: isOrgActive ? 'primary.main' : 'error.main',
						flexShrink: 0,
					}}
				/>
				<Typography
					variant='body2'
					fontWeight={500}
					color='text.primary'
					noWrap
					sx={{ flex: 1 }}
				>
					{orgName}
				</Typography>
				{inSheet && (
					<Chip
						label={isOrgActive ? 'Активна' : 'Неактивна'}
						size='small'
						sx={{
							height: 20,
							fontSize: 10,
							bgcolor: isOrgActive
								? 'rgba(74, 222, 128, 0.12)'
								: 'action.selected',
							color: isOrgActive ? 'primary.main' : 'text.secondary',
						}}
					/>
				)}
				{companyId && (
					<Tooltip title='Настройки компании'>
						<IconButton
							size='small'
							onClick={() => {
								setMoreOpen(false);
								setSettingsOpen(true);
							}}
							sx={{ color: 'text.secondary', flexShrink: 0 }}
						>
							<SettingsOutlinedIcon sx={{ fontSize: 16 }} />
						</IconButton>
					</Tooltip>
				)}
			</Box>
		) : null;

	const desktopSidebar = (
		<Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
			{/* Логотип + бренд */}
			<Box
				sx={{
					display: 'flex',
					alignItems: 'center',
					gap: 1.5,
					px: 2.5,
					py: 2.5,
				}}
			>
				<Box
					sx={{
						width: 36,
						height: 36,
						borderRadius: 1.5,
						bgcolor: 'primary.main',
						display: 'flex',
						alignItems: 'center',
						justifyContent: 'center',
						flexShrink: 0,
						boxShadow: '0 4px 12px rgba(74, 222, 128, 0.3)',
					}}
				>
					<TwoWheelerIcon sx={{ color: 'white', fontSize: 20 }} />
				</Box>
				<Typography
					variant='subtitle1'
					fontWeight={700}
					color='text.primary'
					letterSpacing='-0.01em'
				>
					<span style={{ color: theme.palette.primary.main }}>Мигом!</span>{' '}
					Владелец
				</Typography>
			</Box>

			<Divider />

			{/* Навигация */}
			<List sx={{ px: 1, py: 1.5, flex: 1 }}>
				{NAV_ITEMS.map((item) => {
					const isActive = location.pathname === item.path;
					const Icon = item.icon;
					return (
						<ListItemButton
							key={item.path}
							selected={isActive}
							disabled={item.disabled}
							onClick={() => {
								if (!item.disabled) void navigate(item.path);
							}}
							sx={{
								borderRadius: 2,
								mb: 0.5,
								'&.Mui-selected': {
									bgcolor: alpha(theme.palette.primary.main, 0.1),
									'&:hover': {
										bgcolor: alpha(theme.palette.primary.main, 0.15),
									},
								},
								'&.Mui-disabled': { opacity: 0.45 },
							}}
						>
							<ListItemIcon
								sx={{
									minWidth: 36,
									color: isActive ? 'primary.main' : 'text.secondary',
								}}
							>
								<Icon fontSize='small' />
							</ListItemIcon>
							<ListItemText
								primary={item.label}
								slotProps={{
									primary: {
										variant: 'body2',
										fontWeight: isActive ? 600 : 400,
										color: isActive ? 'primary.main' : 'text.primary',
									},
								}}
							/>
							{item.soon && (
								<Chip
									label='Скоро'
									size='small'
									sx={{
										height: 18,
										fontSize: 10,
										bgcolor: 'action.selected',
										color: 'text.secondary',
									}}
								/>
							)}
						</ListItemButton>
					);
				})}
			</List>

			<Divider />

			{/* Нижняя секция: организация + пользователь + действия */}
			<Box sx={{ p: 2 }}>
				{/* Имя пользователя */}
				{user && (
					<Box
						sx={{
							display: 'flex',
							alignItems: 'center',
							gap: 0.75,
							px: 1,
							mb: 1.5,
						}}
					>
						<AccountCircleOutlinedIcon
							sx={{ fontSize: 16, color: 'text.secondary', flexShrink: 0 }}
						/>
						<Typography variant='caption' color='text.secondary' noWrap>
							{user.full_name}
						</Typography>
					</Box>
				)}

				{orgBlock()}

				<Box
					sx={{
						display: 'flex',
						alignItems: 'center',
						justifyContent: 'space-between',
						px: 0.5,
					}}
				>
					<Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
						<ColorModeButton sx={{ color: 'text.secondary' }} />
						<Typography variant='body2' color='text.secondary'>
							Тема
						</Typography>
					</Box>
					<Box
						sx={{
							display: 'flex',
							alignItems: 'center',
							gap: 0.5,
							cursor: 'pointer',
						}}
						onClick={() => {
							setMoreOpen(false);
							onLogout();
						}}
					>
						<Typography variant='body2' color='error.main'>
							Выйти
						</Typography>
						<IconButton size='small' sx={{ color: 'error.main' }}>
							<LogoutOutlinedIcon fontSize='small' />
						</IconButton>
					</Box>
				</Box>
			</Box>
		</Box>
	);

	return (
		<Box
			sx={{
				display: 'flex',
				minHeight: '100vh',
				bgcolor: 'background.default',
			}}
		>
			{/* Десктопный сайдбар */}
			{!isMobile && (
				<Drawer
					variant='permanent'
					sx={{
						width: DRAWER_WIDTH,
						flexShrink: 0,
						'& .MuiDrawer-paper': {
							width: DRAWER_WIDTH,
							boxSizing: 'border-box',
							bgcolor: 'background.paper',
							borderRight: '1px solid',
							borderColor: 'divider',
						},
					}}
				>
					{desktopSidebar}
				</Drawer>
			)}

			{/* Основной контент */}
			<Box
				component='main'
				sx={{
					flexGrow: 1,
					minWidth: 0,
					overflow: 'auto',
					pb: { xs: `${BOTTOM_NAV_HEIGHT}px`, md: 0 },
				}}
			>
				<Toaster />
				{children}
			</Box>

			{/* Мобильный BottomNavigation */}
			{isMobile && (
				<>
					<Paper
						elevation={0}
						sx={{
							position: 'fixed',
							bottom: 0,
							left: 0,
							right: 0,
							zIndex: theme.zIndex.appBar,
							borderTop: '1px solid',
							borderColor: 'divider',
							bgcolor: 'background.paper',
						}}
					>
						<BottomNavigation
							value={activeNavIndex >= 0 ? activeNavIndex : false}
							sx={{ bgcolor: 'transparent', height: BOTTOM_NAV_HEIGHT }}
						>
							{NAV_ITEMS.map((item) => {
								const Icon = item.icon;
								return (
									<BottomNavigationAction
										key={item.path}
										label={item.label}
										icon={<Icon />}
										disabled={item.disabled}
										onClick={() => {
											if (!item.disabled) void navigate(item.path);
										}}
										sx={{
											'&.Mui-selected': { color: 'primary.main' },
											'&.Mui-disabled': { opacity: 0.4 },
											minWidth: 0,
										}}
									/>
								);
							})}
							<BottomNavigationAction
								label='Ещё'
								icon={<MoreHorizIcon />}
								onClick={() => setMoreOpen(true)}
								sx={{
									'&.Mui-selected': { color: 'primary.main' },
									minWidth: 0,
								}}
							/>
						</BottomNavigation>
					</Paper>

					{/* Bottom sheet «Ещё» */}
					<Drawer
						anchor='bottom'
						open={moreOpen}
						onClose={() => setMoreOpen(false)}
						sx={{
							'& .MuiDrawer-paper': {
								borderTopLeftRadius: 16,
								borderTopRightRadius: 16,
								bgcolor: 'background.paper',
							},
						}}
					>
						<Box sx={{ px: 2.5, pt: 2, pb: 4 }}>
							{/* Handle */}
							<Box
								sx={{
									width: 36,
									height: 4,
									borderRadius: 2,
									bgcolor: 'action.selected',
									mx: 'auto',
									mb: 2.5,
								}}
							/>

							{orgBlock(true)}

							{/* Имя пользователя */}
							{user && (
								<Box
									sx={{
										display: 'flex',
										alignItems: 'center',
										gap: 0.75,
										px: 0.5,
										mb: 2,
									}}
								>
									<AccountCircleOutlinedIcon
										sx={{ fontSize: 16, color: 'text.secondary' }}
									/>
									<Typography variant='body2' color='text.secondary'>
										{user.full_name}
									</Typography>
								</Box>
							)}

							<Divider sx={{ mb: 2 }} />

							{/* Действия */}
							<Box
								sx={{
									display: 'flex',
									alignItems: 'center',
									justifyContent: 'space-between',
									px: 0.5,
								}}
							>
								<Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
									<ColorModeButton sx={{ color: 'text.secondary' }} />
									<Typography variant='body2' color='text.secondary'>
										Тема
									</Typography>
								</Box>
								<Box
									sx={{
										display: 'flex',
										alignItems: 'center',
										gap: 0.5,
										cursor: 'pointer',
									}}
									onClick={() => {
										setMoreOpen(false);
										onLogout();
									}}
								>
									<Typography variant='body2' color='error.main'>
										Выйти
									</Typography>
									<IconButton size='small' sx={{ color: 'error.main' }}>
										<LogoutOutlinedIcon fontSize='small' />
									</IconButton>
								</Box>
							</Box>
						</Box>
					</Drawer>
				</>
			)}

			{/* Диалог настроек компании */}
			{companyId && (
				<CompanySettingsDialog
					open={settingsOpen}
					onClose={() => setSettingsOpen(false)}
					companyId={companyId}
					onDeleted={handleCompanyDeleted}
				/>
			)}
		</Box>
	);
}
