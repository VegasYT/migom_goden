import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogActions,
	Button,
	TextField,
	Stack,
	CircularProgress,
} from '@mui/material';
import { useForm } from '@tanstack/react-form';
import { z } from 'zod';
import type { Category } from '../types';
import { EmojiPicker } from './EmojiPicker';

function validate<T>(s: z.ZodType<T>, v: T) {
	const r = s.safeParse(v);
	return r.success ? undefined : (r.error.issues[0]?.message ?? 'Ошибка');
}

const nameSchema = z.string().min(1, 'Обязательное поле');
const emojiSchema = z.string().min(1, 'Укажите эмодзи');

interface Props {
	open: boolean;
	onClose: () => void;
	category?: Category | null;
	onSubmit: (values: {
		name: string;
		emoji: string;
		sort_order: number;
	}) => void;
	isPending?: boolean;
}

export function CategoryDialog({
	open,
	onClose,
	category,
	onSubmit,
	isPending,
}: Props) {
	return (
		<Dialog open={open} onClose={onClose} maxWidth='xs' fullWidth>
			<DialogTitle>
				{category ? 'Редактировать категорию' : 'Новая категория'}
			</DialogTitle>
			{open && (
				<CategoryForm
					category={category}
					onClose={onClose}
					onSubmit={onSubmit}
					isPending={isPending}
				/>
			)}
		</Dialog>
	);
}

function CategoryForm({
	category,
	onClose,
	onSubmit,
	isPending,
}: Omit<Props, 'open'>) {
	const form = useForm({
		defaultValues: {
			name: category?.name ?? '',
			emoji: category?.emoji ?? '',
			sort_order: String(category?.sort_order ?? 0),
		},
		onSubmit: async ({ value }) => {
			onSubmit({
				name: value.name,
				emoji: value.emoji,
				sort_order: Number(value.sort_order) || 0,
			});
		},
	});

	return (
		<form
			onSubmit={(e) => {
				e.preventDefault();
				void form.handleSubmit();
			}}
		>
			<DialogContent sx={{ pt: 2 }}>
				<Stack spacing={2.5}>
					<form.Field
						name='name'
						validators={{
							onBlur: ({ value }) => validate(nameSchema, value),
							onSubmit: ({ value }) => validate(nameSchema, value),
						}}
					>
						{(field) => {
							const hasError =
								field.state.meta.isTouched &&
								field.state.meta.errors.length > 0;
							return (
								<TextField
									autoFocus
									label='Название'
									value={field.state.value}
									onChange={(e) =>
										field.handleChange(e.target.value)
									}
									onBlur={field.handleBlur}
									error={hasError}
									helperText={
										hasError
											? field.state.meta.errors.join(', ')
											: undefined
									}
									fullWidth
								/>
							);
						}}
					</form.Field>

					<form.Field
						name='emoji'
						validators={{
							onBlur: ({ value }) => validate(emojiSchema, value),
							onSubmit: ({ value }) => validate(emojiSchema, value),
						}}
					>
						{(field) => {
							const hasError =
								field.state.meta.isTouched &&
								field.state.meta.errors.length > 0;
							return (
								<EmojiPicker
									value={field.state.value}
									onChange={(v) => field.handleChange(v)}
									onBlur={field.handleBlur}
									error={hasError}
									helperText={
										hasError
											? field.state.meta.errors.join(', ')
											: 'Выберите эмодзи для категории'
									}
								/>
							);
						}}
					</form.Field>

					<form.Field name='sort_order'>
						{(field) => (
							<TextField
								label='Порядок сортировки'
								type='number'
								value={field.state.value}
								onChange={(e) =>
									field.handleChange(e.target.value)
								}
								onBlur={field.handleBlur}
								fullWidth
							/>
						)}
					</form.Field>
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
							{category ? 'Сохранить' : 'Создать'}
						</Button>
					)}
				</form.Subscribe>
			</DialogActions>
		</form>
	);
}
