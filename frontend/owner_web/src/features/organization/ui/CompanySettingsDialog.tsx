import { useState } from 'react';
import { useForm } from '@tanstack/react-form';
import { z } from 'zod';
import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogActions,
	Button,
	TextField,
	Stack,
	Typography,
	Box,
	Divider,
	CircularProgress,
	Alert,
	List,
	ListItemButton,
	ListItemIcon,
	ListItemText,
	IconButton,
} from '@mui/material';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import RadioButtonUncheckedIcon from '@mui/icons-material/RadioButtonUnchecked';
import AddBusinessOutlinedIcon from '@mui/icons-material/AddBusinessOutlined';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import WarningAmberOutlinedIcon from '@mui/icons-material/WarningAmberOutlined';
import { useQueryClient } from '@tanstack/react-query';
import { toaster } from '@shared/ui/toaster';
import { useOrganization, organizationKeys } from '../api/useOrganization';
import { useMyCompanies, myCompaniesKeys } from '../api/useMyCompanies';
import { useUpdateOrganization } from '../api/useUpdateOrganization';
import { useDeleteOrganization } from '../api/useDeleteOrganization';
import { useOrganizationStore } from '../model/organizationStore';
import { organizationApi } from '../api/organizationApi';
import type { Organization } from '../types';

function validate<T>(s: z.ZodType<T>, v: T) {
	const r = s.safeParse(v);
	return r.success ? undefined : (r.error.issues[0]?.message ?? 'Ошибка');
}

// ─── Форма создания (встроенная) ──────────────────────────────────────────────

interface CreateViewProps {
	onBack: () => void;
	onCreated: (org: Organization) => void;
}

function CreateCompanyView({ onBack, onCreated }: CreateViewProps) {
	const queryClient = useQueryClient();
	const [isPending, setIsPending] = useState(false);
	const [error, setError] = useState<string | null>(null);

	const form = useForm({
		defaultValues: { name: '', description: '' },
		onSubmit: async ({ value }) => {
			setIsPending(true);
			setError(null);
			try {
				const newOrg = await organizationApi.create({
					name: value.name,
					description: value.description || undefined,
				});
				queryClient.setQueryData(organizationKeys.detail(newOrg.id), newOrg);
				void queryClient.invalidateQueries({ queryKey: myCompaniesKeys.all });
				toaster.success({ title: 'Организация создана!' });
				onCreated(newOrg);
			} catch (e) {
				const detail =
					(e as { response?: { data?: { detail?: string } } })?.response?.data?.detail ??
					'Ошибка при создании';
				setError(detail);
			} finally {
				setIsPending(false);
			}
		},
	});

	return (
		<form
			onSubmit={(e) => {
				e.preventDefault();
				void form.handleSubmit();
			}}
		>
			<DialogContent sx={{ pt: 1 }}>
				<Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
					<IconButton size='small' onClick={onBack}>
						<ArrowBackIcon fontSize='small' />
					</IconButton>
					<Typography variant='subtitle2'>Новое предприятие</Typography>
				</Box>

				<Stack spacing={2.5}>
					<form.Field
						name='name'
						validators={{
							onBlur: ({ value }) =>
								validate(z.string().min(2, 'Минимум 2 символа'), value),
							onSubmit: ({ value }) =>
								validate(z.string().min(2, 'Минимум 2 символа'), value),
						}}
					>
						{(field) => {
							const hasError =
								field.state.meta.isTouched && field.state.meta.errors.length > 0;
							return (
								<TextField
									autoFocus
									label='Название организации'
									placeholder='Например: Кофейня «Утро»'
									value={field.state.value}
									onChange={(e) => field.handleChange(e.target.value)}
									onBlur={field.handleBlur}
									error={hasError}
									helperText={hasError ? field.state.meta.errors.join(', ') : undefined}
									fullWidth
								/>
							);
						}}
					</form.Field>

					<form.Field name='description'>
						{(field) => (
							<TextField
								label='Описание (необязательно)'
								placeholder='Кратко о вашей компании'
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								onBlur={field.handleBlur}
								fullWidth
								multiline
								rows={3}
							/>
						)}
					</form.Field>

					{error && (
						<Typography color='error' variant='body2'>
							{error}
						</Typography>
					)}
				</Stack>
			</DialogContent>

			<DialogActions sx={{ px: 3, pb: 2.5 }}>
				<Button onClick={onBack} color='inherit'>
					Назад
				</Button>
				<form.Subscribe selector={(s) => s.canSubmit}>
					{(canSubmit) => (
						<Button
							type='submit'
							variant='contained'
							disabled={!canSubmit || isPending}
							startIcon={isPending ? <CircularProgress size={16} color='inherit' /> : null}
						>
							Создать
						</Button>
					)}
				</form.Subscribe>
			</DialogActions>
		</form>
	);
}

// ─── Настройки текущей компании ───────────────────────────────────────────────

interface SettingsViewProps {
	org: Organization;
	companies: Organization[];
	companiesLoading: boolean;
	onClose: () => void;
	onDeleted: () => void;
	onCreateNew: () => void;
}

function SettingsView({
	org,
	companies,
	companiesLoading,
	onClose,
	onDeleted,
	onCreateNew,
}: SettingsViewProps) {
	const update = useUpdateOrganization();
	const deleteOrg = useDeleteOrganization();
	const setCompanyId = useOrganizationStore((s) => s.setCompanyId);
	const [confirmingDelete, setConfirmingDelete] = useState(false);

	const form = useForm({
		defaultValues: {
			name: org.name,
			description: org.description ?? '',
		},
		onSubmit: async ({ value }) => {
			await update.mutateAsync({
				id: org.id,
				dto: {
					name: value.name,
					description: value.description || null,
				},
			});
			onClose();
		},
	});

	const handleDelete = async () => {
		await deleteOrg.mutateAsync(org.id);
		onDeleted();
	};

	const handleSwitch = (id: number) => {
		if (id !== org.id) {
			setCompanyId(id);
			onClose();
		}
	};

	return (
		<form
			onSubmit={(e) => {
				e.preventDefault();
				void form.handleSubmit();
			}}
		>
			<DialogContent sx={{ pt: 2 }}>
				{/* Список компаний */}
				<Typography variant='caption' color='text.secondary' fontWeight={600} textTransform='uppercase' letterSpacing='0.08em'>
					Мои предприятия
				</Typography>

				{companiesLoading ? (
					<Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
						<CircularProgress size={20} />
					</Box>
				) : (
					<List disablePadding sx={{ mt: 0.5, mb: 1 }}>
						{companies.map((c) => {
							const isCurrent = c.id === org.id;
							return (
								<ListItemButton
									key={c.id}
									selected={isCurrent}
									onClick={() => handleSwitch(c.id)}
									sx={{
										borderRadius: 1.5,
										py: 0.75,
										'&.Mui-selected': { bgcolor: 'action.selected' },
									}}
								>
									<ListItemIcon sx={{ minWidth: 32 }}>
										{isCurrent ? (
											<CheckCircleIcon sx={{ fontSize: 18 }} color='primary' />
										) : (
											<RadioButtonUncheckedIcon sx={{ fontSize: 18, color: 'text.disabled' }} />
										)}
									</ListItemIcon>
									<ListItemText
										primary={c.name}
										primaryTypographyProps={{
											variant: 'body2',
											fontWeight: isCurrent ? 600 : 400,
										}}
									/>
								</ListItemButton>
							);
						})}
						<ListItemButton
							onClick={onCreateNew}
							sx={{ borderRadius: 1.5, py: 0.75, color: 'primary.main' }}
						>
							<ListItemIcon sx={{ minWidth: 32 }}>
								<AddBusinessOutlinedIcon sx={{ fontSize: 18 }} color='primary' />
							</ListItemIcon>
							<ListItemText
								primary='Создать предприятие'
								primaryTypographyProps={{ variant: 'body2', fontWeight: 500 }}
							/>
						</ListItemButton>
					</List>
				)}

				<Divider sx={{ mb: 2 }} />

				{/* Настройки текущей компании */}
				<Stack spacing={2.5}>
					<form.Field
						name='name'
						validators={{
							onBlur: ({ value }) =>
								validate(z.string().min(2, 'Минимум 2 символа'), value),
							onSubmit: ({ value }) =>
								validate(z.string().min(2, 'Минимум 2 символа'), value),
						}}
					>
						{(field) => {
							const hasError =
								field.state.meta.isTouched && field.state.meta.errors.length > 0;
							return (
								<TextField
									label='Название компании'
									value={field.state.value}
									onChange={(e) => field.handleChange(e.target.value)}
									onBlur={field.handleBlur}
									error={hasError}
									helperText={hasError ? field.state.meta.errors.join(', ') : undefined}
									fullWidth
								/>
							);
						}}
					</form.Field>

					<form.Field name='description'>
						{(field) => (
							<TextField
								label='Описание (необязательно)'
								placeholder='Кратко о вашей компании'
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								onBlur={field.handleBlur}
								fullWidth
								multiline
								rows={3}
							/>
						)}
					</form.Field>
				</Stack>

				{/* Опасная зона */}
				<Box mt={3.5}>
					<Divider sx={{ mb: 2 }} />
					<Typography
						variant='caption'
						color='text.secondary'
						fontWeight={600}
						textTransform='uppercase'
						letterSpacing='0.08em'
					>
						Опасная зона
					</Typography>

					{!confirmingDelete ? (
						<Box mt={1.5}>
							<Button
								variant='outlined'
								color='error'
								size='small'
								onClick={() => setConfirmingDelete(true)}
							>
								Удалить компанию
							</Button>
						</Box>
					) : (
						<Alert
							severity='error'
							icon={<WarningAmberOutlinedIcon fontSize='inherit' />}
							sx={{ mt: 1.5 }}
						>
							<Typography variant='body2' mb={1.5}>
								Все данные компании, точки продаж и меню будут удалены безвозвратно.
								Это действие нельзя отменить.
							</Typography>
							<Box sx={{ display: 'flex', gap: 1 }}>
								<Button
									variant='contained'
									color='error'
									size='small'
									disabled={deleteOrg.isPending}
									startIcon={
										deleteOrg.isPending ? (
											<CircularProgress size={14} color='inherit' />
										) : null
									}
									onClick={() => void handleDelete()}
								>
									Удалить навсегда
								</Button>
								<Button
									size='small'
									color='inherit'
									onClick={() => setConfirmingDelete(false)}
									disabled={deleteOrg.isPending}
								>
									Отмена
								</Button>
							</Box>
						</Alert>
					)}
				</Box>
			</DialogContent>

			<DialogActions sx={{ px: 3, pb: 2.5 }}>
				<Button onClick={onClose} color='inherit'>
					Отмена
				</Button>
				<form.Subscribe selector={(s) => s.canSubmit}>
					{(canSubmit) => (
						<Button
							type='submit'
							variant='contained'
							disabled={!canSubmit || update.isPending}
							startIcon={
								update.isPending ? <CircularProgress size={16} color='inherit' /> : null
							}
						>
							Сохранить
						</Button>
					)}
				</form.Subscribe>
			</DialogActions>
		</form>
	);
}

// ─── Диалог-обёртка ──────────────────────────────────────────────────────────

interface Props {
	open: boolean;
	onClose: () => void;
	companyId: number;
	onDeleted: () => void;
}

export function CompanySettingsDialog({ open, onClose, companyId, onDeleted }: Props) {
	const { data: org, isLoading: orgLoading } = useOrganization(open ? companyId : null);
	const { data: companies, isLoading: companiesLoading } = useMyCompanies();
	const setCompanyId = useOrganizationStore((s) => s.setCompanyId);
	const [view, setView] = useState<'settings' | 'create'>('settings');

	const handleClose = () => {
		setView('settings');
		onClose();
	};

	const handleCreated = (newOrg: Organization) => {
		setCompanyId(newOrg.id);
		setView('settings');
		onClose();
	};

	const handleDeleted = () => {
		setView('settings');
		// Если есть другие компании - переключиться на первую, иначе - на создание
		const remaining = companies?.filter((c) => c.id !== companyId) ?? [];
		if (remaining.length > 0) {
			setCompanyId(remaining[0].id);
			onClose();
		} else {
			onDeleted();
		}
	};

	return (
		<Dialog open={open} onClose={handleClose} maxWidth='sm' fullWidth>
			<DialogTitle>
				{view === 'settings' ? 'Настройки компании' : 'Новое предприятие'}
			</DialogTitle>

			{open && view === 'create' && (
				<CreateCompanyView onBack={() => setView('settings')} onCreated={handleCreated} />
			)}

			{open && view === 'settings' && orgLoading && (
				<DialogContent>
					<Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
						<CircularProgress />
					</Box>
				</DialogContent>
			)}

			{open && view === 'settings' && org && (
				<SettingsView
					org={org}
					companies={companies ?? []}
					companiesLoading={companiesLoading}
					onClose={handleClose}
					onDeleted={handleDeleted}
					onCreateNew={() => setView('create')}
				/>
			)}
		</Dialog>
	);
}
