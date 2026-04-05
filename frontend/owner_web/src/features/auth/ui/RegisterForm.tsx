import { useForm } from '@tanstack/react-form';
import { z } from 'zod';
import {
	Stack,
	TextField,
	Button,
	Typography,
	InputAdornment,
	CircularProgress,
	MenuItem,
} from '@mui/material';
import PersonOutlineIcon from '@mui/icons-material/PersonOutline';
import EmailOutlinedIcon from '@mui/icons-material/EmailOutlined';
import PhoneOutlinedIcon from '@mui/icons-material/PhoneOutlined';
import LockOutlinedIcon from '@mui/icons-material/LockOutlined';
import BadgeOutlinedIcon from '@mui/icons-material/BadgeOutlined';
import { useRegister } from '../api/useRegister';
import { ROLE_OWNER, ROLE_OUTLET_MANAGER } from '../types';

type RegisterFormValues = {
	full_name: string;
	email: string;
	password: string;
	phone: string;
	role_id: number;
};

function validate<T>(schema: z.ZodType<T>, value: T): string | undefined {
	const result = schema.safeParse(value);
	return result.success ? undefined : (result.error.issues[0]?.message ?? 'Ошибка');
}

export function RegisterForm() {
	const register = useRegister();

	const form = useForm({
		defaultValues: {
			full_name: '',
			email: '',
			password: '',
			phone: '',
			role_id: ROLE_OWNER,
		} satisfies RegisterFormValues,
		onSubmit: async ({ value }) => {
			await register.mutateAsync({
				...value,
				phone: value.phone || undefined,
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
				{/* Full Name */}
				<form.Field
					name="full_name"
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
								id="register-full-name"
								type="text"
								label="Полное имя"
								placeholder="Иван Иванов"
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
												<PersonOutlineIcon fontSize="small" color="action" />
											</InputAdornment>
										),
									},
								}}
							/>
						);
					}}
				</form.Field>

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
								id="register-email"
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

				{/* Phone - необязательно */}
				<form.Field name="phone">
					{(field) => (
						<TextField
							id="register-phone"
							type="tel"
							label={
								<>
									Телефон{' '}
									<Typography component="span" variant="body2" color="text.secondary">
										(необязательно)
									</Typography>
								</>
							}
							placeholder="+7 (999) 000-00-00"
							value={field.state.value}
							onChange={(e) => field.handleChange(e.target.value)}
							onBlur={field.handleBlur}
							fullWidth
							slotProps={{
								input: {
									startAdornment: (
										<InputAdornment position="start">
											<PhoneOutlinedIcon fontSize="small" color="action" />
										</InputAdornment>
									),
								},
							}}
						/>
					)}
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
								id="register-password"
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

				{/* Роль */}
				<form.Field name="role_id">
					{(field) => (
						<TextField
							id="register-role"
							select
							label="Роль"
							value={field.state.value}
							onChange={(e) => field.handleChange(Number(e.target.value))}
							onBlur={field.handleBlur}
							fullWidth
							slotProps={{
								input: {
									startAdornment: (
										<InputAdornment position="start">
											<BadgeOutlinedIcon fontSize="small" color="action" />
										</InputAdornment>
									),
								},
							}}
						>
							<MenuItem value={ROLE_OWNER}>Владелец бизнеса</MenuItem>
							<MenuItem value={ROLE_OUTLET_MANAGER}>Менеджер точки</MenuItem>
						</TextField>
					)}
				</form.Field>

				<form.Subscribe selector={(s) => s.canSubmit}>
					{(canSubmit) => (
						<Button
							id="register-submit"
							type="submit"
							variant="contained"
							size="large"
							fullWidth
							disabled={!canSubmit || register.isPending}
							startIcon={
								register.isPending ? <CircularProgress size={18} color="inherit" /> : null
							}
							sx={{ fontWeight: 600, py: 1.5 }}
						>
							Создать аккаунт
						</Button>
					)}
				</form.Subscribe>

				{register.isError && (
					<Typography color="error" variant="body2" textAlign="center">
						{(register.error as { response?: { data?: { detail?: string } } })?.response?.data
							?.detail ?? 'Произошла ошибка. Попробуйте снова.'}
					</Typography>
				)}
			</Stack>
		</form>
	);
}
