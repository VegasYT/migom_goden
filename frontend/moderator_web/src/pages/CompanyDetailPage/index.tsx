import { useState } from 'react';
import { useParams, useNavigate } from 'react-router';
import {
	Box,
	Typography,
	CircularProgress,
	Alert,
	Tabs,
	Tab,
	Button,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import { useAuthGuard, useAuthStore } from '@features/auth';
import {
	useCompany,
	useCompanyOutlets,
	useCompanyMenu,
	useBlockCompany,
	useDeleteCompany,
	CompanyInfoCard,
	CompanyOutletsList,
	CompanyMenuView,
	BlockCompanyDialog,
	DeleteCompanyDialog,
} from '@features/companies';
import { AppLayout } from '@pages/layouts/AppLayout';

export default function CompanyDetailPage() {
	const { isAuthenticated } = useAuthGuard();
	const { companyId } = useParams<{ companyId: string }>();
	const navigate = useNavigate();
	const logout = useAuthStore((s) => s.logout);

	const id = companyId ? Number(companyId) : null;

	const {
		data: company,
		isLoading,
		error,
	} = useCompany(id);
	const { data: outlets, isLoading: outletsLoading } = useCompanyOutlets(id);
	const { data: menu, isLoading: menuLoading } = useCompanyMenu(id);

	const blockMutation = useBlockCompany();
	const deleteMutation = useDeleteCompany();

	const [tab, setTab] = useState(0);
	const [blockOpen, setBlockOpen] = useState(false);
	const [deleteOpen, setDeleteOpen] = useState(false);

	const handleBlock = () => {
		if (!company) return;
		blockMutation.mutate(
			{ id: company.id, blocked: company.is_blocked },
			{ onSuccess: () => setBlockOpen(false) }
		);
	};

	const handleDelete = () => {
		if (!company) return;
		deleteMutation.mutate(company.id, {
			onSuccess: () => {
				setDeleteOpen(false);
				void navigate('/companies', { replace: true });
			},
		});
	};

	if (!isAuthenticated) return null;

	return (
		<AppLayout onLogout={logout}>
			<Box sx={{ p: { xs: 2, md: 4 } }}>
				<Button
					startIcon={<ArrowBackIcon />}
					onClick={() => void navigate('/companies')}
					sx={{ mb: 2, color: 'text.secondary' }}
				>
					Назад к списку
				</Button>

				{isLoading && (
					<Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
						<CircularProgress />
					</Box>
				)}

				{error && (
					<Alert severity='error' sx={{ mb: 2 }}>
						Не удалось загрузить данные компании
					</Alert>
				)}

				{company && (
					<>
						<CompanyInfoCard
							company={company}
							onBlock={() => setBlockOpen(true)}
							onDelete={() => setDeleteOpen(true)}
							blockPending={blockMutation.isPending}
						/>

						<Box sx={{ mt: 3 }}>
							<Tabs
								value={tab}
								onChange={(_, v: number) => setTab(v)}
								sx={{ mb: 2 }}
							>
								<Tab
									label={`Торговые точки${outlets ? ` (${outlets.length})` : ''}`}
								/>
								<Tab label='Меню' />
							</Tabs>

							{tab === 0 && (
								<>
									{outletsLoading ? (
										<Box
											sx={{
												display: 'flex',
												justifyContent: 'center',
												py: 4,
											}}
										>
											<CircularProgress size={24} />
										</Box>
									) : outlets ? (
										<CompanyOutletsList outlets={outlets} />
									) : (
										<Typography
											variant='body2'
											color='text.secondary'
										>
											Не удалось загрузить точки
										</Typography>
									)}
								</>
							)}

							{tab === 1 && (
								<>
									{menuLoading ? (
										<Box
											sx={{
												display: 'flex',
												justifyContent: 'center',
												py: 4,
											}}
										>
											<CircularProgress size={24} />
										</Box>
									) : menu ? (
										<CompanyMenuView menu={menu} />
									) : (
										<Typography
											variant='body2'
											color='text.secondary'
										>
											Не удалось загрузить меню
										</Typography>
									)}
								</>
							)}
						</Box>

						<BlockCompanyDialog
							open={blockOpen}
							onClose={() => setBlockOpen(false)}
							company={company}
							onConfirm={handleBlock}
							isPending={blockMutation.isPending}
						/>

						<DeleteCompanyDialog
							open={deleteOpen}
							onClose={() => setDeleteOpen(false)}
							company={company}
							onConfirm={handleDelete}
							isPending={deleteMutation.isPending}
						/>
					</>
				)}
			</Box>
		</AppLayout>
	);
}
