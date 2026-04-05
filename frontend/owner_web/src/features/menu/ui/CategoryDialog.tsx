import { useForm } from '@tanstack/react-form';
import { z } from 'zod';
import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogActions,
	Button,
	TextField,
	CircularProgress,
} from '@mui/material';
import { useCreateCategory } from '../api/useCreateCategory';
import { useUpdateCategory } from '../api/useUpdateCategory';
import type { MenuCategory } from '../types';

const schema = z.object({
	name: z.string().min(2, 'Минимум 2 символа'),
});

function validate<T>(s: z.ZodType<T>, v: T) {
	const r = s.safeParse(v);
	return r.success ? undefined : (r.error.issues[0]?.message ?? 'Ошибка');
}

interface Props {
	open: boolean;
	onClose: () => void;
	companyId: number;
	category?: MenuCategory;
}

function CategoryForm({ onClose, companyId, category }: Omit<Props, 'open'>) {
	const create = useCreateCategory();
	const update = useUpdateCategory();
	const isPending = create.isPending || update.isPending;

	const form = useForm({
		defaultValues: { name: category?.name ?? '' },
		onSubmit: async ({ value }) => {
			if (category) {
				await update.mutateAsync({ companyId, categoryId: category.id, dto: value });
			} else {
				await create.mutateAsync({ companyId, dto: value });
			}
			onClose();
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
				<form.Field
					name="name"
					validators={{
						onBlur: ({ value }) => validate(schema.shape.name, value),
						onSubmit: ({ value }) => validate(schema.shape.name, value),
					}}
				>
					{(field) => {
						const hasError = field.state.meta.isTouched && field.state.meta.errors.length > 0;
						return (
							<TextField
								autoFocus
								label="Название категории"
								placeholder="Например: Горячие напитки"
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
			</DialogContent>

			<DialogActions sx={{ px: 3, pb: 2.5 }}>
				<Button onClick={onClose} color="inherit">
					Отмена
				</Button>
				<form.Subscribe selector={(s) => s.canSubmit}>
					{(canSubmit) => (
						<Button
							type="submit"
							variant="contained"
							disabled={!canSubmit || isPending}
							startIcon={isPending ? <CircularProgress size={16} color="inherit" /> : null}
						>
							{category ? 'Сохранить' : 'Создать'}
						</Button>
					)}
				</form.Subscribe>
			</DialogActions>
		</form>
	);
}

export function CategoryDialog({ open, onClose, companyId, category }: Props) {
	return (
		<Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
			<DialogTitle>{category ? 'Редактировать категорию' : 'Новая категория'}</DialogTitle>
			{open && <CategoryForm onClose={onClose} companyId={companyId} category={category} />}
		</Dialog>
	);
}
