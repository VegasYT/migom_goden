import { useForm } from '@tanstack/react-form';
import { z } from 'zod';
import {
	Stack,
	TextField,
	Button,
	Typography,
	InputAdornment,
	CircularProgress,
} from '@mui/material';
import BusinessOutlinedIcon from '@mui/icons-material/BusinessOutlined';
import { useCreateOrganization } from '../api/useCreateOrganization';

type FormValues = {
	name: string;
	description: string;
};

function validate<T>(schema: z.ZodType<T>, value: T): string | undefined {
	const result = schema.safeParse(value);
	return result.success ? undefined : (result.error.issues[0]?.message ?? 'Ошибка');
}

export function CreateOrganizationForm() {
	const createOrg = useCreateOrganization();

	const form = useForm({
		defaultValues: { name: '', description: '' } satisfies FormValues,
		onSubmit: async ({ value }) => {
			await createOrg.mutateAsync({
				name: value.name,
				description: value.description || undefined,
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
			<Stack spacing={2.5}>
				{/* Название */}
				<form.Field
					name="name"
					validators={{
						onBlur: ({ value }) =>
							validate(z.string().min(2, 'Минимум 2 символа'), value),
						onSubmit: ({ value }) =>
							validate(z.string().min(2, 'Минимум 2 символа'), value),
					}}
				>
					{(field) => {
						const hasError = field.state.meta.isTouched && field.state.meta.errors.length > 0;
						return (
							<TextField
								id="org-name"
								type="text"
								label="Название организации"
								placeholder="Например: Кофейня «Утро»"
								value={field.state.value}
								onChange={(e) => field.handleChange(e.target.value)}
								onBlur={field.handleBlur}
								error={hasError}
								helperText={hasError ? field.state.meta.errors.join(', ') : undefined}
								fullWidth
								slotProps={{
									input: {
										startAdornment: (
											<InputAdornment position="start">
												<BusinessOutlinedIcon fontSize="small" color="action" />
											</InputAdornment>
										),
									},
								}}
							/>
						);
					}}
				</form.Field>

				{/* Описание */}
				<form.Field name="description">
					{(field) => (
						<TextField
							id="org-description"
							label="Описание (необязательно)"
							placeholder="Кратко опишите вашу организацию"
							value={field.state.value}
							onChange={(e) => field.handleChange(e.target.value)}
							onBlur={field.handleBlur}
							fullWidth
							multiline
							rows={3}
						/>
					)}
				</form.Field>

				<form.Subscribe selector={(s) => s.canSubmit}>
					{(canSubmit) => (
						<Button
							id="org-submit"
							type="submit"
							variant="contained"
							size="large"
							fullWidth
							disabled={!canSubmit || createOrg.isPending}
							startIcon={
								createOrg.isPending ? <CircularProgress size={18} color="inherit" /> : null
							}
							sx={{ fontWeight: 600, py: 1.5 }}
						>
							Создать организацию
						</Button>
					)}
				</form.Subscribe>

				{createOrg.isError && (
					<Typography color="error" variant="body2" textAlign="center">
						{(createOrg.error as { response?: { data?: { detail?: string } } })?.response?.data
							?.detail ?? 'Произошла ошибка. Попробуйте снова.'}
					</Typography>
				)}
			</Stack>
		</form>
	);
}
