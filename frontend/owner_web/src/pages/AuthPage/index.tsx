import { Box, Typography, Tabs, Tab } from '@mui/material';
import TwoWheelerIcon from '@mui/icons-material/TwoWheeler';
import { useState } from 'react';
import { LoginForm, RegisterForm, useGuestGuard } from '@features/auth';
import { ColorModeButton } from '@shared/ui/color-mode';
import { Toaster } from '@shared/ui/toaster';

export default function AuthPage() {
	useGuestGuard();
	const [tab, setTab] = useState(0);

	return (
		<>
			<Toaster />
			<Box
				sx={{
					minHeight: '100dvh',
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'center',
					bgcolor: 'background.default',
					position: 'relative',
					overflow: 'hidden',
				}}
			>
				{/* Декоративные фоновые круги */}
				<Box
					sx={{
						position: 'absolute',
						top: '-10%',
						left: '-5%',
						width: 500,
						height: 500,
						borderRadius: '50%',
						bgcolor: 'primary.main',
						opacity: 0.06,
						filter: 'blur(80px)',
						pointerEvents: 'none',
					}}
				/>
				<Box
					sx={{
						position: 'absolute',
						bottom: '-10%',
						right: '-5%',
						width: 600,
						height: 600,
						borderRadius: '50%',
						bgcolor: 'primary.main',
						opacity: 0.04,
						filter: 'blur(100px)',
						pointerEvents: 'none',
					}}
				/>

				{/* Кнопка смены темы */}
				<Box sx={{ position: 'absolute', top: 16, right: 16 }}>
					<ColorModeButton />
				</Box>

				{/* Карточка */}
				<Box
					sx={{
						width: '100%',
						maxWidth: 440,
						mx: 2,
						bgcolor: 'background.paper',
						borderRadius: 3,
						border: '1px solid',
						borderColor: 'divider',
						boxShadow: '0 24px 64px rgba(0,0,0,0.12)',
						p: { xs: 3, sm: 5 },
						animation: 'authCardIn 0.35s cubic-bezier(0.34, 1.56, 0.64, 1) both',
					}}
				>
					{/* Логотип */}
					<Box
						sx={{
							display: 'flex',
							flexDirection: 'column',
							alignItems: 'center',
							mb: 4,
							gap: 0.5,
						}}
					>
						<Box
							sx={{
								width: 52,
								height: 52,
								borderRadius: 2,
								bgcolor: 'primary.main',
								display: 'flex',
								alignItems: 'center',
								justifyContent: 'center',
								mb: 1.5,
								boxShadow: '0 8px 24px rgba(74, 222, 128, 0.35)',
							}}
						>
							<TwoWheelerIcon sx={{ color: 'white', fontSize: 28 }} />
						</Box>
						<Typography
							variant="h5"
							fontWeight={700}
							color="text.primary"
							letterSpacing="-0.02em"
						>
							Migom Owner
						</Typography>
						<Typography variant="body2" color="text.secondary">
							Панель управления для владельцев
						</Typography>
					</Box>

					{/* Вкладки */}
					<Tabs
						value={tab}
						onChange={(_, v) => setTab(v)}
						variant="fullWidth"
						sx={{
							mb: 3,
							bgcolor: 'action.hover',
							borderRadius: 2,
							p: 0.5,
							minHeight: 40,
							'& .MuiTabs-indicator': { display: 'none' },
							'& .MuiTab-root': {
								borderRadius: 1.5,
								minHeight: 36,
								fontWeight: 500,
								textTransform: 'none',
								transition: 'all 0.2s',
							},
							'& .Mui-selected': {
								bgcolor: 'background.paper',
								boxShadow: '0 1px 4px rgba(0,0,0,0.1)',
								color: 'text.primary !important',
							},
						}}
					>
						<Tab id="tab-login" label="Вход" />
						<Tab id="tab-register" label="Регистрация" />
					</Tabs>

					{tab === 0 && <LoginForm />}
					{tab === 1 && <RegisterForm />}
				</Box>
			</Box>

			<style>{`
				@keyframes authCardIn {
					from { opacity: 0; transform: scale(0.94) translateY(12px); }
					to   { opacity: 1; transform: scale(1) translateY(0); }
				}
			`}</style>
		</>
	);
}
