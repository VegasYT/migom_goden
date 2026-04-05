import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogContentText,
	DialogActions,
	Button,
	CircularProgress,
} from '@mui/material';
import type { Company } from '../types';

interface Props {
	open: boolean;
	onClose: () => void;
	company: Company | null;
	onConfirm: () => void;
	isPending?: boolean;
}

export function DeleteCompanyDialog({
	open,
	onClose,
	company,
	onConfirm,
	isPending,
}: Props) {
	return (
		<Dialog open={open} onClose={onClose} maxWidth='xs' fullWidth>
			<DialogTitle>Удалить компанию</DialogTitle>
			<DialogContent>
				<DialogContentText>
					Вы уверены, что хотите удалить компанию «{company?.name}»? Это
					действие необратимо.
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
