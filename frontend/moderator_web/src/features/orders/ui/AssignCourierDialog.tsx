import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogActions,
	Button,
	List,
	ListItemButton,
	ListItemText,
	Typography,
	CircularProgress,
	Box,
	Chip,
} from '@mui/material';
import type { Order, Courier, MovementType } from '../types';

const MOVEMENT_LABEL: Record<MovementType, string> = {
	walk: 'Пешком',
	scooter: 'Самокат',
	car: 'Авто',
};

interface Props {
	open: boolean;
	onClose: () => void;
	order: Order | null;
	couriers: Courier[];
	couriersLoading?: boolean;
	onAssign: (courierId: number) => void;
	isPending?: boolean;
}

export function AssignCourierDialog({
	open,
	onClose,
	order,
	couriers,
	couriersLoading,
	onAssign,
	isPending,
}: Props) {
	const available = couriers.filter((c) => !c.is_blocked);

	return (
		<Dialog open={open} onClose={onClose} maxWidth='xs' fullWidth>
			<DialogTitle>
				Назначить курьера на заказ #{order?.id}
			</DialogTitle>
			<DialogContent sx={{ px: 0 }}>
				{couriersLoading ? (
					<Box
						sx={{
							display: 'flex',
							justifyContent: 'center',
							py: 4,
						}}
					>
						<CircularProgress size={24} />
					</Box>
				) : available.length === 0 ? (
					<Typography
						variant='body2'
						color='text.secondary'
						sx={{ px: 3, py: 2 }}
					>
						Нет доступных курьеров
					</Typography>
				) : (
					<List disablePadding>
						{available.map((courier) => (
							<ListItemButton
								key={courier.id}
								onClick={() => onAssign(courier.id)}
								disabled={isPending}
								sx={{ px: 3 }}
							>
								<ListItemText
									primary={`Курьер #${courier.id}`}
									secondary={`${courier.type_movement ? MOVEMENT_LABEL[courier.type_movement] : 'Не указан'}, радиус ${courier.radius_km} км`}
								/>
								{courier.current_latitude != null && (
									<Chip
										label='Онлайн'
										size='small'
										color='success'
										sx={{ height: 20, fontSize: 11 }}
									/>
								)}
							</ListItemButton>
						))}
					</List>
				)}
			</DialogContent>
			<DialogActions sx={{ px: 3, pb: 2.5 }}>
				<Button onClick={onClose} color='inherit'>
					Отмена
				</Button>
			</DialogActions>
		</Dialog>
	);
}
