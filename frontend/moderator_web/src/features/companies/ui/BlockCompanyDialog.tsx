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

export function BlockCompanyDialog({
	open,
	onClose,
	company,
	onConfirm,
	isPending,
}: Props) {
	const isBlocked = company?.is_blocked ?? false;

	return (
		<Dialog open={open} onClose={onClose} maxWidth='xs' fullWidth>
			<DialogTitle>
				{isBlocked ? 'Разблокировать компанию' : 'Заблокировать компанию'}
			</DialogTitle>
			<DialogContent>
				<DialogContentText>
					{isBlocked
						? `Вы уверены, что хотите разблокировать компанию «${company?.name}»? Компания снова сможет принимать заказы.`
						: `Вы уверены, что хотите заблокировать компанию «${company?.name}»? Компания не сможет принимать заказы.`}
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
