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
import EmailOutlinedIcon from '@mui/icons-material/EmailOutlined';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import { useLogin } from '../api/useLogin';

type LoginFormValues = {
	email: string;
	password: string;
};

function validate<T>(schema: z.ZodType<T>, value: T): string | undefined {
	const result = schema.safeParse(value);
	return result.success ? undefined : (result.error.issues[0]?.message ?? 'Ошибка');
}

export function LoginForm() {
	const login = useLogin();

	const form = useForm({
		defaultValues: { email: '', password: '' } satisfies LoginFormValues,
		onSubmit: async ({ value }) => {
			await login.mutateAsync(value);
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
				{/* Email */}
				<form.Field
					name="email"
					validators={{
						onBlur: ({ value }) =>
							validate(z.string().email('Некорректный email'), value),
						onSubmit: ({ value }) =>
							validate(z.string().email('Некорректный email'), value),
					}}
				>
					{(field) => {
						const hasError = field.state.meta.isTouched && field.state.meta.errors.length > 0;
						return (
							<TextField
								id="login-email"
								type="email"
								label="Email"
								placeholder="owner@migom.ru"
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
												<EmailOutlinedIcon fontSize="small" color="action" />
											</InputAdornment>
										),
									},
								}}
							/>
						);
					}}
				</form.Field>

				{/* Password */}
				<form.Field
					name="password"
					validators={{
						onBlur: ({ value }) =>
							validate(z.string().min(8, 'Минимум 8 символов'), value),
						onSubmit: ({ value }) =>
							validate(z.string().min(8, 'Минимум 8 символов'), value),
					}}
				>
					{(field) => {
						const hasError = field.state.meta.isTouched && field.state.meta.errors.length > 0;
						return (
							<TextField
								id="login-password"
								type="password"
								label="Пароль"
								placeholder="Минимум 8 символов"
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
												<LockOutlinedIcon fontSize="small" color="action" />
											</InputAdornment>
										),
									},
								}}
							/>
						);
					}}
				</form.Field>

				<form.Subscribe selector={(s) => s.canSubmit}>
					{(canSubmit) => (
						<Button
							id="login-submit"
							type="submit"
							variant="contained"
							size="large"
							fullWidth
							disabled={!canSubmit || login.isPending}
							startIcon={login.isPending ? <CircularProgress size={18} color="inherit" /> : null}
							sx={{ fontWeight: 600, py: 1.5 }}
						>
							Войти
						</Button>
					)}
				</form.Subscribe>

				{login.isError && (
					<Typography color="error" variant="body2" textAlign="center">
						{(login.error as { response?: { data?: { detail?: string } } })?.response?.data
							?.detail ?? 'Произошла ошибка. Попробуйте снова.'}
					</Typography>
				)}
			</Stack>
		</form>
	);
}
