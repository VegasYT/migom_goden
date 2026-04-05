import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogContentText,
	DialogActions,
	Button,
	CircularProgress,
} from '@mui/material';
import type { Order } from '../types';

interface Props {
	open: boolean;
	onClose: () => void;
	order: Order | null;
	onConfirm: () => void;
	isPending?: boolean;
}

export function CancelOrderDialog({
	open,
	onClose,
	order,
	onConfirm,
	isPending,
}: Props) {
	return (
		<Dialog open={open} onClose={onClose} maxWidth='xs' fullWidth>
			<DialogTitle>Отменить заказ</DialogTitle>
			<DialogContent>
				<DialogContentText>
					Вы уверены, что хотите принудительно отменить заказ #{order?.id}
					? Это действие необратимо.
				</DialogContentText>
			</DialogContent>
			<DialogActions sx={{ px: 3, pb: 2.5 }}>
				<Button onClick={onClose} color='inherit'>
					Назад
				</Button>
				<Button
					variant='contained'
					color='error'
					onClick={onConfirm}
					disabled={isPending}
					startIcon={
						isPending ? (
							<CircularProgress size={16} color='inherit' />
						) : null
					}
				>
					Отменить заказ
				</Button>
			</DialogActions>
		</Dialog>
	);
}
