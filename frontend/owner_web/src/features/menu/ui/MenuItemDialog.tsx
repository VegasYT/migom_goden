import { useRef, useState } from 'react';
import { useForm } from '@tanstack/react-form';
import { z } from 'zod';
import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogActions,
	Button,
	TextField,
	MenuItem as MuiMenuItem,
	Select,
	InputLabel,
	FormControl,
	InputAdornment,
	Switch,
	FormControlLabel,
	Stack,
	CircularProgress,
	Box,
	Typography,
} from '@mui/material';
import UploadFileOutlinedIcon from '@mui/icons-material/UploadFileOutlined';
import ImageOutlinedIcon from '@mui/icons-material/ImageOutlined';
import { useCreateMenuItem } from '../api/useCreateMenuItem';
import { useUpdateMenuItem } from '../api/useUpdateMenuItem';
import { useGlobalCategories } from '../api/useGlobalCategories';
import { useUploadItemPhoto } from '../api/useUploadItemPhoto';
import type { GlobalCategory, MenuItem } from '../types';

const priceSchema = z
	.string()
	.min(1, 'Укажите цену')
	.refine(
		(v) => /^\d+(\.\d{1,2})?$/.test(v) && parseFloat(v) > 0,
		'Введите положительное число (например: 150 или 99.99)',
	);

function validate<T>(s: z.ZodType<T>, v: T) {
	const r = s.safeParse(v);
	return r.success ? undefined : (r.error.issues[0]?.message ?? 'Ошибка');
}

interface Props {
	open: boolean;
	onClose: () => void;
	companyId: number;
	item?: MenuItem;
	defaultCategoryId?: number;
}

interface FormProps {
	onClose: () => void;
	companyId: number;
	item?: MenuItem;
	defaultCategoryId?: number;
	globalCategories: GlobalCategory[];
}

function MenuItemForm({
	onClose,
	companyId,
	item,
	defaultCategoryId,
	globalCategories,
}: FormProps) {
	const create = useCreateMenuItem();
	const update = useUpdateMenuItem();
	const uploadPhoto = useUploadItemPhoto();
	const isPending = create.isPending || update.isPending;

	const fileInputRef = useRef<HTMLInputElement>(null);
	const [currentPhotoUrl, setCurrentPhotoUrl] = useState(item?.photo_url ?? null);

	const form = useForm({
		defaultValues: {
			name: item?.name ?? '',
			description: item?.description ?? '',
			price: item?.price ?? '',
			category_id:
				item?.category_id ?? defaultCategoryId ?? globalCategories[0]?.id ?? 0,
			is_active: item?.is_active ?? true,
		},
		onSubmit: async ({ value }) => {
			const dto = {
				name: value.name,
				description: value.description || undefined,
				price: value.price,
				category_id: value.category_id,
			};
			if (item) {
				await update.mutateAsync({
					companyId,
					itemId: item.id,
					dto: { ...dto, is_active: value.is_active },
				});
			} else {
				await create.mutateAsync({ companyId, dto });
			}
			onClose();
		},
	});

	const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
		const file = e.target.files?.[0];
		if (file && item) {
			uploadPhoto.mutate(
				{ companyId, itemId: item.id, file },
				{ onSuccess: (updated) => setCurrentPhotoUrl(updated.photo_url) },
			);
			e.target.value = '';
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
				<Stack spacing={2.5}>
					{/* Фото - только в режиме редактирования */}
					{item && (
						<Box>
							<Typography variant='caption' color='text.secondary' display='block' mb={1}>
								Фото товара
							</Typography>
							<Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
								<Box
									sx={{
										width: 64,
										height: 64,
										borderRadius: 2,
										bgcolor: 'action.hover',
										backgroundImage: currentPhotoUrl
											? `url(${currentPhotoUrl})`
											: undefined,
										backgroundSize: 'cover',
										backgroundPosition: 'center',
										display: 'flex',
										alignItems: 'center',
										justifyContent: 'center',
										flexShrink: 0,
										border: '1px solid',
										borderColor: 'divider',
										overflow: 'hidden',
									}}
								>
									{!currentPhotoUrl && (
										<ImageOutlinedIcon sx={{ color: 'text.secondary' }} />
									)}
								</Box>
								<Box>
									<Button
										size='small'
										variant='outlined'
										startIcon={
											uploadPhoto.isPending ? (
												<CircularProgress size={14} color='inherit' />
											) : (
												<UploadFileOutlinedIcon />
											)
										}
										disabled={uploadPhoto.isPending}
										onClick={() => fileInputRef.current?.click()}
									>
										{currentPhotoUrl ? 'Заменить' : 'Загрузить фото'}
									</Button>
									<Typography
										variant='caption'
										color='text.secondary'
										display='block'
										mt={0.5}
									>
										JPEG, PNG или WebP
									</Typography>
									<input
										ref={fileInputRef}
										type='file'
										accept='image/jpeg,image/png,image/webp'
										style={{ display: 'none' }}
										onChange={handleFileChange}
									/>
								</Box>
							</Box>
						</Box>
					)}

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
								field.state.meta.isTouched && field.state.meta.errors.length > 0;
							return (
								<TextField
									autoFocus={!item}
									label='Название'
									placeholder='Капучино'
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

					{/* Категория */}
					<form.Field name='category_id'>
						{(field) => (
							<FormControl fullWidth>
								<InputLabel>Категория</InputLabel>
								<Select
									label='Категория'
									value={field.state.value}
									onChange={(e) => field.handleChange(Number(e.target.value))}
								>
									{globalCategories.map((cat) => (
										<MuiMenuItem key={cat.id} value={cat.id}>
											{cat.emoji} {cat.name}
										</MuiMenuItem>
									))}
								</Select>
							</FormControl>
						)}
					</form.Field>

					{/* Цена */}
					<form.Field
						name='price'
						validators={{
							onBlur: ({ value }) => validate(priceSchema, value),
							onSubmit: ({ value }) => validate(priceSchema, value),
						}}
					>
						{(field) => {
							const hasError =
								field.state.meta.isTouched && field.state.meta.errors.length > 0;
							return (
								<TextField
									label='Цена'
									placeholder='150'
									value={field.state.value}
									onChange={(e) => field.handleChange(e.target.value)}
									onBlur={field.handleBlur}
									error={hasError}
									helperText={
										hasError ? field.state.meta.errors.join(', ') : undefined
									}
									fullWidth
									slotProps={{
										input: {
											endAdornment: (
												<InputAdornment position='end'>₽</InputAdornment>
											),
										},
									}}
								/>
							);
						}}
					</form.Field>

					{/* Описание */}
					<form.Field name='description'>
						{(field) => (
							<TextField
								label='Описание (необязательно)'
								placeholder='Молочный кофе с нежной пенкой'
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								onBlur={field.handleBlur}
								fullWidth
								multiline
								rows={2}
							/>
						)}
					</form.Field>

					{/* Активность - только в режиме редактирования */}
					{item && (
						<form.Field name='is_active'>
							{(field) => (
								<FormControlLabel
									control={
										<Switch
											checked={field.state.value}
											onChange={(e) => field.handleChange(e.target.checked)}
										/>
									}
									label='Позиция активна (видна покупателям)'
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
								isPending ? <CircularProgress size={16} color='inherit' /> : null
							}
						>
							{item ? 'Сохранить' : 'Добавить'}
						</Button>
					)}
				</form.Subscribe>
			</DialogActions>
		</form>
	);
}

function MenuItemFormWrapper({
	companyId,
	item,
	defaultCategoryId,
	onClose,
}: Omit<Props, 'open'>) {
	const { data: globalCategories = [], isLoading } = useGlobalCategories();

	if (isLoading) {
		return (
			<>
				<DialogContent>
					<Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
						<CircularProgress />
					</Box>
				</DialogContent>
				<DialogActions sx={{ px: 3, pb: 2.5 }}>
					<Button onClick={onClose} color='inherit'>
						Отмена
					</Button>
				</DialogActions>
			</>
		);
	}

	return (
		<MenuItemForm
			onClose={onClose}
			companyId={companyId}
			item={item}
			defaultCategoryId={defaultCategoryId}
			globalCategories={globalCategories}
		/>
	);
}

export function MenuItemDialog({
	open,
	onClose,
	companyId,
	item,
	defaultCategoryId,
}: Props) {
	return (
		<Dialog open={open} onClose={onClose} maxWidth='sm' fullWidth>
			<DialogTitle>{item ? 'Редактировать позицию' : 'Новая позиция'}</DialogTitle>
			{open && (
				<MenuItemFormWrapper
					companyId={companyId}
					item={item}
					defaultCategoryId={defaultCategoryId}
					onClose={onClose}
				/>
			)}
		</Dialog>
	);
}
