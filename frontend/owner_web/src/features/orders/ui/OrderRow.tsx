import { useState } from 'react';
import {
	TableRow,
	TableCell,
	Typography,
	Chip,
	Box,
	IconButton,
	Tooltip,
	Collapse,
	CircularProgress,
} from '@mui/material';
import PlayArrowOutlinedIcon from '@mui/icons-material/PlayArrowOutlined';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import CancelOutlinedIcon from '@mui/icons-material/CancelOutlined';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import KeyboardArrowUpIcon from '@mui/icons-material/KeyboardArrowUp';
import MopedOutlinedIcon from '@mui/icons-material/MopedOutlined';
import ShoppingBagOutlinedIcon from '@mui/icons-material/ShoppingBagOutlined';
import { ORDER_STATUS_LABEL, ORDER_STATUS_COLOR } from '../lib/orderStatus';
import { useOrderAction } from '../api/useOrderAction';
import { OrderRouteMap } from './OrderRouteMap';
import type { Order } from '../types';

interface OutletInfo {
	id: number;
	latitude: string;
	longitude: string;
	name: string;
}

interface Props {
	order: Order;
	outlets?: OutletInfo[];
	hideActions?: boolean;
}

function formatDate(iso: string) {
	return new Date(iso).toLocaleString('ru-RU', {
		day: '2-digit',
		month: '2-digit',
		year: '2-digit',
		hour: '2-digit',
		minute: '2-digit',
	});
}

export function OrderRow({ order, outlets, hideActions }: Props) {
	const [expanded, setExpanded] = useState(false);
	const action = useOrderAction();
	const isPending = action.isPending;

	const canAssemble = order.status === 'assigned';
	const canReady = order.status === 'assembling';
	const canCancel = !['delivered', 'cancelled', 'received'].includes(
		order.status
	);

	const itemsSummary = order.items
		.map((i) => `${i.name} ×${i.quantity}`)
		.join(', ');

	// Координаты для карты
	const outlet = outlets?.find((o) => o.id === order.outlet_id);
	const outletCoords: [number, number] | null = outlet
		? [parseFloat(outlet.latitude), parseFloat(outlet.longitude)]
		: null;
	const deliveryCoords: [number, number] | null =
		order.delivery_address?.latitude != null && order.delivery_address?.longitude != null
			? [order.delivery_address.latitude, order.delivery_address.longitude]
			: null;
	const canShowMap =
		outletCoords != null &&
		deliveryCoords != null &&
		!isNaN(outletCoords[0]) &&
		!isNaN(deliveryCoords[0]) &&
		order.delivery_type === 'delivery';

	const colSpan = hideActions ? 7 : 8;

	return (
		<>
			<TableRow
				hover
				sx={{
					'& > *': { borderBottom: expanded ? 'unset' : undefined },
					cursor: 'pointer',
				}}
				onClick={() => setExpanded((p) => !p)}
			>
				{/* Раскрытие */}
				<TableCell sx={{ width: 40, px: 1 }}>
					<IconButton size='small'>
						{expanded ? (
							<KeyboardArrowUpIcon fontSize='small' />
						) : (
							<KeyboardArrowDownIcon fontSize='small' />
						)}
					</IconButton>
				</TableCell>

				{/* № */}
				<TableCell>
					<Typography variant='body2' fontWeight={600}>
						#{order.id}
					</Typography>
				</TableCell>

				{/* Статус */}
				<TableCell>
					<Chip
						label={ORDER_STATUS_LABEL[order.status]}
						size='small'
						color={
							ORDER_STATUS_COLOR[order.status] as
								| 'info'
								| 'warning'
								| 'success'
								| 'error'
								| 'primary'
								| 'default'
						}
						sx={{ height: 22, fontSize: 11 }}
					/>
				</TableCell>

				{/* Тип */}
				<TableCell>
					<Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
						{order.delivery_type === 'delivery' ? (
							<MopedOutlinedIcon
								sx={{ fontSize: 14, color: 'text.secondary' }}
							/>
						) : (
							<ShoppingBagOutlinedIcon
								sx={{ fontSize: 14, color: 'text.secondary' }}
							/>
						)}
						<Typography variant='body2' color='text.secondary'>
							{order.delivery_type === 'delivery' ? 'Доставка' : 'Самовывоз'}
						</Typography>
					</Box>
				</TableCell>

				{/* Позиции (кратко) */}
				<TableCell sx={{ maxWidth: 250 }}>
					<Typography variant='body2' color='text.secondary' noWrap>
						{itemsSummary}
					</Typography>
				</TableCell>

				{/* Сумма */}
				<TableCell align='right'>
					<Typography variant='body2' fontWeight={600}>
						{Number(order.total_price).toLocaleString('ru-RU')} ₽
					</Typography>
				</TableCell>

				{/* Дата */}
				<TableCell>
					<Typography variant='caption' color='text.secondary'>
						{formatDate(order.created_at)}
					</Typography>
				</TableCell>

				{/* Действия */}
				{!hideActions && (
					<TableCell align='right' onClick={(e) => e.stopPropagation()}>
						<Box
							sx={{ display: 'flex', gap: 0.25, justifyContent: 'flex-end' }}
						>
							{canAssemble && (
								<Tooltip title='Начать сборку'>
									<IconButton
										size='small'
										disabled={isPending}
										onClick={() =>
											action.mutate({ orderId: order.id, action: 'assemble' })
										}
										sx={{ color: 'warning.main' }}
									>
										{isPending ? (
											<CircularProgress size={16} />
										) : (
											<PlayArrowOutlinedIcon fontSize='small' />
										)}
									</IconButton>
								</Tooltip>
							)}
							{canReady && (
								<Tooltip title='Готов к выдаче'>
									<IconButton
										size='small'
										disabled={isPending}
										onClick={() =>
											action.mutate({ orderId: order.id, action: 'ready' })
										}
										sx={{ color: 'success.main' }}
									>
										{isPending ? (
											<CircularProgress size={16} />
										) : (
											<CheckCircleOutlineIcon fontSize='small' />
										)}
									</IconButton>
								</Tooltip>
							)}
							{canCancel && (
								<Tooltip title='Отменить заказ'>
									<IconButton
										size='small'
										disabled={isPending}
										onClick={() =>
											action.mutate({ orderId: order.id, action: 'cancel' })
										}
										sx={{ color: 'error.main' }}
									>
										{isPending ? (
											<CircularProgress size={16} />
										) : (
											<CancelOutlinedIcon fontSize='small' />
										)}
									</IconButton>
								</Tooltip>
							)}
						</Box>
					</TableCell>
				)}
			</TableRow>

			{/* Развёрнутая строка */}
			<TableRow>
				<TableCell
					colSpan={colSpan}
					sx={{ py: 0, borderBottom: expanded ? undefined : 'none' }}
				>
					<Collapse in={expanded} timeout='auto' unmountOnExit>
						<Box sx={{ py: 2, px: 1 }}>
							{/* Позиции */}
							<Typography
								variant='caption'
								fontWeight={600}
								color='text.secondary'
								display='block'
								mb={1}
							>
								Позиции заказа
							</Typography>
							{order.items.map((item) => (
								<Box
									key={item.id}
									sx={{
										display: 'flex',
										justifyContent: 'space-between',
										py: 0.5,
									}}
								>
									<Typography variant='body2'>
										{item.name} × {item.quantity}
									</Typography>
									<Typography variant='body2' color='text.secondary'>
										{Number(item.subtotal).toLocaleString('ru-RU')} ₽
									</Typography>
								</Box>
							))}

							{/* Комментарий */}
							{order.comment && (
								<Box mt={1.5}>
									<Typography
										variant='caption'
										fontWeight={600}
										color='text.secondary'
										display='block'
										mb={0.5}
									>
										Комментарий
									</Typography>
									<Typography variant='body2'>{order.comment}</Typography>
								</Box>
							)}

							{/* Мета */}
							<Box mt={1.5} sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
								{order.delivery_time != null && (
									<Typography variant='caption' color='text.secondary'>
										Время доставки: ~{order.delivery_time} мин
									</Typography>
								)}
								{order.leave_at_door && (
									<Typography variant='caption' color='text.secondary'>
										Оставить у двери
									</Typography>
								)}
								{order.courier_id && (
									<Typography variant='caption' color='text.secondary'>
										Курьер: #{order.courier_id}
									</Typography>
								)}
							</Box>

							{/* Карта маршрута */}
							{canShowMap && (
								<OrderRouteMap
									outletCoords={outletCoords}
									deliveryCoords={deliveryCoords}
									outletName={outlet?.name}
								/>
							)}
						</Box>
					</Collapse>
				</TableCell>
			</TableRow>
		</>
	);
}
