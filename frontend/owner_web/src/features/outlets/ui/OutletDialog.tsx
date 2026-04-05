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
	Switch,
	FormControlLabel,
	CircularProgress,
	InputAdornment,
	Box,
} from '@mui/material';
import MapOutlinedIcon from '@mui/icons-material/MapOutlined';
import { useCreateOutlet } from '../api/useCreateOutlet';
import { useUpdateOutlet } from '../api/useUpdateOutlet';
import { MapPickerDialog } from './MapPickerDialog';
import type { Outlet } from '../types';

function validate<T>(s: z.ZodType<T>, v: T) {
	const r = s.safeParse(v);
	return r.success ? undefined : (r.error.issues[0]?.message ?? 'Ошибка');
}

const feeSchema = z
	.string()
	.refine(
		(v) => v === '' || (!isNaN(Number(v)) && Number(v) >= 0),
		'Введите целое число ≥ 0'
	);

// ─── Фильтр ввода числовых полей ─────────────────────────────────────────────

function filterNumeric(value: string): string {
	let v = value.replace(/[^0-9.]/g, '');
	const dotIdx = v.indexOf('.');
	if (dotIdx !== -1) {
		v = v.slice(0, dotIdx + 1) + v.slice(dotIdx + 1).replace(/\./g, '');
	}
	return v;
}

interface Props {
	open: boolean;
	onClose: () => void;
	companyId: number;
	outlet?: Outlet;
}

function OutletForm({ onClose, companyId, outlet }: Omit<Props, 'open'>) {
	const create = useCreateOutlet();
	const update = useUpdateOutlet();
	const isPending = create.isPending || update.isPending;
	const [mapPickerOpen, setMapPickerOpen] = useState(false);

	const form = useForm({
		defaultValues: {
			name: outlet?.name ?? '',
			address: outlet?.address ?? '',
			latitude: outlet?.latitude ?? '',
			longitude: outlet?.longitude ?? '',
			delivery_fee: outlet?.delivery_fee?.toString() ?? '0',
			free_delivery_from: outlet?.free_delivery_from?.toString() ?? '',
			min_order_price: outlet?.min_order_price?.toString() ?? '',
			opens_at: outlet?.opens_at?.slice(0, 5) ?? '00:00',
			closes_at: outlet?.closes_at?.slice(0, 5) ?? '23:59',
			is_active: outlet?.is_active ?? true,
		},
		onSubmit: async ({ value }) => {
			const base = {
				name: value.name,
				address: value.address,
				latitude: value.latitude,
				longitude: value.longitude,
				delivery_fee: value.delivery_fee ? Number(value.delivery_fee) : 0,
				free_delivery_from: value.free_delivery_from
					? Number(value.free_delivery_from)
					: null,
				min_order_price: value.min_order_price
					? Number(value.min_order_price)
					: null,
				opens_at: `${value.opens_at}:00`,
				closes_at: `${value.closes_at}:00`,
			};
			if (outlet) {
				await update.mutateAsync({
					companyId,
					outletId: outlet.id,
					dto: { ...base, is_active: value.is_active },
				});
			} else {
				await create.mutateAsync({ companyId, dto: base });
			}
			onClose();
		},
	});

	return (
		<>
		<form
			onSubmit={(e) => {
				e.preventDefault();
				void form.handleSubmit();
			}}
		>
			<DialogContent sx={{ pt: 2 }}>
				<Stack spacing={2.5}>
					{/* Название */}
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
								field.state.meta.isTouched &&
								field.state.meta.errors.length > 0;
							return (
								<TextField
									autoFocus
									label='Название точки'
									placeholder='Главный офис'
									value={field.state.value}
									onChange={(e) => field.handleChange(e.target.value)}
									onBlur={field.handleBlur}
									error={hasError}
									helperText={
										hasError ? field.state.meta.errors.join(', ') : undefined
									}
									fullWidth
								/>
							);
						}}
					</form.Field>

					{/* Адрес и координаты */}
					<form.Field
						name='latitude'
						validators={{
							onSubmit: ({ value }) =>
								value ? undefined : 'Выберите точку на карте',
						}}
					>
						{(field) => {
							const hasError =
								field.state.meta.isTouched &&
								field.state.meta.errors.length > 0;
							return (
								<Box>
									<Box
										sx={{
											display: 'flex',
											alignItems: 'center',
											justifyContent: 'space-between',
											mb: 1,
										}}
									>
										<Typography variant='caption' color='text.secondary'>
											Адрес точки
										</Typography>
										<Button
											size='small'
											startIcon={
												<MapOutlinedIcon sx={{ fontSize: '14px !important' }} />
											}
											onClick={() => setMapPickerOpen(true)}
											sx={{
												fontSize: 12,
												color: 'text.secondary',
												px: 1,
												py: 0.25,
												minWidth: 0,
												'&:hover': { color: 'primary.main' },
											}}
										>
											Выбрать на карте
										</Button>
									</Box>
									<TextField
										placeholder='Выберите точку на карте'
										value={form.state.values.address}
										error={hasError}
										helperText={
											hasError ? field.state.meta.errors.join(', ') : undefined
										}
										fullWidth
										slotProps={{ input: { readOnly: true } }}
										sx={{ '& .MuiInputBase-input': { cursor: 'default' } }}
									/>
								</Box>
							);
						}}
					</form.Field>

					{/* Доставка */}
					<Box>
						<Typography
							variant='caption'
							color='text.secondary'
							display='block'
							mb={1}
						>
							Условия доставки
						</Typography>
						<Stack spacing={2}>
							<form.Field
								name='delivery_fee'
								validators={{
									onBlur: ({ value }) => validate(feeSchema, value),
								}}
							>
								{(field) => {
									const hasError =
										field.state.meta.isTouched &&
										field.state.meta.errors.length > 0;
									return (
										<TextField
											label='Стоимость доставки'
											placeholder='0'
											value={field.state.value}
											onChange={(e) =>
												field.handleChange(filterNumeric(e.target.value))
											}
											onBlur={field.handleBlur}
											error={hasError}
											helperText={
												hasError
													? field.state.meta.errors.join(', ')
													: 'Введите 0 для бесплатной доставки'
											}
											fullWidth
											slotProps={{
												input: {
													endAdornment: (
														<InputAdornment position='end'>₽</InputAdornment>
													),
												},
												htmlInput: { inputMode: 'decimal' },
											}}
										/>
									);
								}}
							</form.Field>

							<Stack direction='row' spacing={2}>
								<form.Field name='free_delivery_from'>
									{(field) => (
										<TextField
											label='Бесплатно от (₽)'
											placeholder='Не указано'
											value={field.state.value}
											onChange={(e) =>
												field.handleChange(filterNumeric(e.target.value))
											}
											onBlur={field.handleBlur}
											fullWidth
											slotProps={{
												input: {
													endAdornment: (
														<InputAdornment position='end'>₽</InputAdornment>
													),
												},
												htmlInput: { inputMode: 'decimal' },
											}}
										/>
									)}
								</form.Field>
								<form.Field name='min_order_price'>
									{(field) => (
										<TextField
											label='Мин. заказ'
											placeholder='Не указано'
											value={field.state.value}
											onChange={(e) =>
												field.handleChange(filterNumeric(e.target.value))
											}
											onBlur={field.handleBlur}
											fullWidth
											slotProps={{
												input: {
													endAdornment: (
														<InputAdornment position='end'>₽</InputAdornment>
													),
												},
												htmlInput: { inputMode: 'decimal' },
											}}
										/>
									)}
								</form.Field>
							</Stack>
						</Stack>
					</Box>

					{/* Часы работы */}
					<Box>
						<Typography
							variant='caption'
							color='text.secondary'
							display='block'
							mb={1}
						>
							Часы приёма заказов
						</Typography>
						<Stack direction='row' spacing={2}>
							<form.Field name='opens_at'>
								{(field) => (
									<TextField
										label='Открывается'
										type='time'
										value={field.state.value}
										onChange={(e) => field.handleChange(e.target.value)}
										onBlur={field.handleBlur}
										fullWidth
										slotProps={{ htmlInput: { step: 60 } }}
									/>
								)}
							</form.Field>
							<form.Field name='closes_at'>
								{(field) => (
									<TextField
										label='Закрывается'
										type='time'
										value={field.state.value}
										onChange={(e) => field.handleChange(e.target.value)}
										onBlur={field.handleBlur}
										fullWidth
										slotProps={{ htmlInput: { step: 60 } }}
									/>
								)}
							</form.Field>
						</Stack>
					</Box>

					{/* Активность - только в режиме редактирования */}
					{outlet && (
						<form.Field name='is_active'>
							{(field) => (
								<FormControlLabel
									control={
										<Switch
											checked={field.state.value}
											onChange={(e) => field.handleChange(e.target.checked)}
										/>
									}
									label='Точка активна (принимает заказы)'
								/>
							)}
						</form.Field>
					)}
				</Stack>
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
							disabled={!canSubmit || isPending}
							startIcon={
								isPending ? (
									<CircularProgress size={16} color='inherit' />
								) : null
							}
						>
							{outlet ? 'Сохранить' : 'Создать'}
						</Button>
					)}
				</form.Subscribe>
			</DialogActions>
		</form>

		<MapPickerDialog
			open={mapPickerOpen}
			onClose={() => setMapPickerOpen(false)}
			initialLat={form.state.values.latitude}
			initialLng={form.state.values.longitude}
			onConfirm={(lat, lng, address) => {
				form.setFieldValue('latitude', lat);
				form.setFieldValue('longitude', lng);
				if (address) {
					form.setFieldValue('address', address);
				}
			}}
		/>
		</>
	);
}

export function OutletDialog({ open, onClose, companyId, outlet }: Props) {
	return (
		<Dialog open={open} onClose={onClose} maxWidth='sm' fullWidth>
			<DialogTitle>
				{outlet ? 'Редактировать точку' : 'Новая точка продаж'}
			</DialogTitle>
			{open && (
				<OutletForm onClose={onClose} companyId={companyId} outlet={outlet} />
			)}
		</Dialog>
	);
}
