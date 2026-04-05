import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogContentText,
	DialogActions,
	Button,
	CircularProgress,
} from '@mui/material';
import type { Category } from '../types';

interface Props {
	open: boolean;
	onClose: () => void;
	category: Category | null;
	onConfirm: () => void;
	isPending?: boolean;
}

export function DeleteCategoryDialog({
	open,
	onClose,
	category,
	onConfirm,
	isPending,
}: Props) {
	return (
		<Dialog open={open} onClose={onClose} maxWidth='xs' fullWidth>
			<DialogTitle>Удалить категорию</DialogTitle>
			<DialogContent>
				<DialogContentText>
					Вы уверены, что хотите удалить категорию «{category?.emoji}{' '}
					{category?.name}»? Это действие необратимо.
				</DialogContentText>
			</DialogContent>
			<DialogActions sx={{ px: 3, pb: 2.5 }}>
				<Button onClick={onClose} color='inherit'>
					Отмена
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
					Удалить
				</Button>
			</DialogActions>
		</Dialog>
	);
}
