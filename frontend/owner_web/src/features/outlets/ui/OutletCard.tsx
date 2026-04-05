import { useState } from 'react';
import {
	Box,
	Typography,
	Chip,
	IconButton,
	Tooltip,
	Divider,
	Button,
} from '@mui/material';
import EditOutlinedIcon from '@mui/icons-material/EditOutlined';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import LocationOnOutlinedIcon from '@mui/icons-material/LocationOnOutlined';
import LocalShippingOutlinedIcon from '@mui/icons-material/LocalShippingOutlined';
import PlaylistAddCheckIcon from '@mui/icons-material/PlaylistAddCheck';
import PeopleOutlinedIcon from '@mui/icons-material/PeopleOutlined';
import { useDeleteOutlet } from '../api/useDeleteOutlet';
import { OutletDialog } from './OutletDialog';
import { OutletAvailabilityDialog } from './OutletAvailabilityDialog';
import { OutletManagersDialog } from './OutletManagersDialog';
import type { Outlet } from '../types';

interface Props {
	outlet: Outlet;
	companyId: number;
}

function formatFee(value: number | null, prefix: string): string | null {
	if (value === null || value === undefined) return null;
	return `${prefix}: ${value.toLocaleString('ru-RU')} ₽`;
}

export function OutletCard({ outlet, companyId }: Props) {
	const [editOpen, setEditOpen] = useState(false);
	const [availabilityOpen, setAvailabilityOpen] = useState(false);
	const [managersOpen, setManagersOpen] = useState(false);
	const deleteOutlet = useDeleteOutlet();

	const deliveryInfo = [
		outlet.delivery_fee > 0
			? `Доставка ${outlet.delivery_fee.toLocaleString('ru-RU')} ₽`
			: 'Бесплатная доставка',
		formatFee(outlet.free_delivery_from, 'Бесплатно от'),
		formatFee(outlet.min_order_price, 'Мин. заказ'),
	].filter(Boolean);

	return (
		<>
			<Box
				sx={{
					bgcolor: 'background.paper',
					border: '1px solid',
					borderColor: 'divider',
					borderRadius: 3,
					overflow: 'hidden',
					transition: 'box-shadow 0.2s',
					'&:hover': {
						boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
					},
				}}
			>
				{/* Шапка карточки */}
				<Box
					sx={{
						display: 'flex',
						alignItems: 'flex-start',
						justifyContent: 'space-between',
						p: 2.5,
						pb: 2,
					}}
				>
					<Box sx={{ flex: 1, minWidth: 0 }}>
						<Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
							<Typography fontWeight={600} color="text.primary" noWrap>
								{outlet.name}
							</Typography>
							<Chip
								label={outlet.is_active ? 'Активна' : 'Неактивна'}
								size="small"
								sx={{
									height: 20,
									fontSize: 11,
									flexShrink: 0,
									bgcolor: outlet.is_active
										? 'rgba(74, 222, 128, 0.12)'
										: 'action.selected',
									color: outlet.is_active ? 'primary.main' : 'text.secondary',
								}}
							/>
						</Box>

						<Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
							<LocationOnOutlinedIcon
								sx={{ fontSize: 14, color: 'text.secondary', flexShrink: 0 }}
							/>
							<Typography variant="body2" color="text.secondary" noWrap>
								{outlet.address}
							</Typography>
						</Box>
					</Box>

					{/* Действия */}
					<Box sx={{ display: 'flex', gap: 0.25, ml: 1, flexShrink: 0 }}>
						<Tooltip title="Редактировать">
							<IconButton size="small" onClick={() => setEditOpen(true)}>
								<EditOutlinedIcon fontSize="small" />
							</IconButton>
						</Tooltip>
						<Tooltip title="Удалить точку">
							<IconButton
								size="small"
								onClick={() => deleteOutlet.mutate({ companyId, outletId: outlet.id })}
								disabled={deleteOutlet.isPending}
							>
								<DeleteOutlineIcon fontSize="small" />
							</IconButton>
						</Tooltip>
					</Box>
				</Box>

				{/* Детали доставки */}
				{deliveryInfo.length > 0 && (
					<>
						<Divider />
						<Box
							sx={{
								display: 'flex',
								alignItems: 'center',
								gap: 0.75,
								px: 2.5,
								py: 1.5,
								flexWrap: 'wrap',
							}}
						>
							<LocalShippingOutlinedIcon
								sx={{ fontSize: 14, color: 'text.secondary', flexShrink: 0 }}
							/>
							{deliveryInfo.map((info, i) => (
								<Box key={i} sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
									{i > 0 && (
										<Box
											sx={{
												width: 3,
												height: 3,
												borderRadius: '50%',
												bgcolor: 'text.secondary',
												opacity: 0.4,
											}}
										/>
									)}
									<Typography variant="caption" color="text.secondary">
										{info}
									</Typography>
								</Box>
							))}
						</Box>
					</>
				)}

				{/* Управление товарами */}
				<Divider />
				<Box sx={{ display: 'flex', px: 2.5, py: 1, gap: 0.5 }}>
					<Button
						size="small"
						variant="text"
						startIcon={<PlaylistAddCheckIcon sx={{ fontSize: '14px !important' }} />}
						onClick={() => setAvailabilityOpen(true)}
						sx={{ fontSize: 12, color: 'text.secondary', textTransform: 'none', minWidth: 0 }}
					>
						Товары в точке
					</Button>
					<Button
						size="small"
						variant="text"
						startIcon={<PeopleOutlinedIcon sx={{ fontSize: '14px !important' }} />}
						onClick={() => setManagersOpen(true)}
						sx={{ fontSize: 12, color: 'text.secondary', textTransform: 'none', minWidth: 0 }}
					>
						Менеджеры
					</Button>
				</Box>
			</Box>

			<OutletDialog
				open={editOpen}
				onClose={() => setEditOpen(false)}
				companyId={companyId}
				outlet={outlet}
			/>
			<OutletAvailabilityDialog
				open={availabilityOpen}
				onClose={() => setAvailabilityOpen(false)}
				outlet={outlet}
				companyId={companyId}
			/>
			<OutletManagersDialog
				open={managersOpen}
				onClose={() => setManagersOpen(false)}
				outlet={outlet}
			/>
		</>
	);
}
