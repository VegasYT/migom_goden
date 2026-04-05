import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogContentText,
	DialogActions,
	Button,
	CircularProgress,
} from '@mui/material';
import type { Courier } from '../types';

interface Props {
	open: boolean;
	onClose: () => void;
	courier: Courier | null;
	onConfirm: () => void;
	isPending?: boolean;
}

export function BlockCourierDialog({
	open,
	onClose,
	courier,
	onConfirm,
	isPending,
}: Props) {
	const isBlocked = courier?.is_blocked ?? false;

	return (
		<Dialog open={open} onClose={onClose} maxWidth='xs' fullWidth>
			<DialogTitle>
				{isBlocked
					? 'Разблокировать курьера'
					: 'Заблокировать курьера'}
			</DialogTitle>
			<DialogContent>
				<DialogContentText>
					{isBlocked
						? `Вы уверены, что хотите разблокировать курьера #${courier?.id}? Он снова сможет принимать заказы.`
						: `Вы уверены, что хотите заблокировать курьера #${courier?.id}? Он не сможет принимать заказы.`}
				</DialogContentText>
			</DialogContent>
			<DialogActions sx={{ px: 3, pb: 2.5 }}>
				<Button onClick={onClose} color='inherit'>
					Отмена
				</Button>
				<Button
					variant='contained'
					color={isBlocked ? 'success' : 'warning'}
					onClick={onConfirm}
					disabled={isPending}
					startIcon={
						isPending ? (
							<CircularProgress size={16} color='inherit' />
						) : null
					}
				>
					{isBlocked ? 'Разблокировать' : 'Заблокировать'}
				</Button>
			</DialogActions>
		</Dialog>
	);
}
