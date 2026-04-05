import { useState } from 'react';
import {
	TableRow,
	TableCell,
	Typography,
	Chip,
	IconButton,
	Box,
	Collapse,
	Divider,
} from '@mui/material';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import KeyboardArrowUpIcon from '@mui/icons-material/KeyboardArrowUp';
import PersonAddOutlinedIcon from '@mui/icons-material/PersonAddOutlined';
import CancelOutlinedIcon from '@mui/icons-material/CancelOutlined';
import MopedOutlinedIcon from '@mui/icons-material/MopedOutlined';
import ShoppingBagOutlinedIcon from '@mui/icons-material/ShoppingBagOutlined';
import { Tooltip } from '@shared/ui/tooltip';
import type { Order } from '../types';
import { ORDER_STATUS_LABEL, ORDER_STATUS_COLOR } from '../types';

function formatDate(iso: string) {
	return new Date(iso).toLocaleString('ru-RU', {
		day: '2-digit',
		month: '2-digit',
		year: 'numeric',
		hour: '2-digit',
		minute: '2-digit',
	});
}

interface Props {
	order: Order;
	onAssign: (order: Order) => void;
	onCancel: (order: Order) => void;
}

export function OrderRow({ order, onAssign, onCancel }: Props) {
	const [expanded, setExpanded] = useState(false);

	const canAssign = ['new', 'ready_for_pickup'].includes(order.status);
	const canCancel = !['delivered', 'cancelled', 'received'].includes(
		order.status
	);

	const itemsSummary = order.items
		.map((i) => `${i.name} ×${i.quantity}`)
		.join(', ');

	return (
		<>
			<TableRow
				hover
				sx={{ cursor: 'pointer' }}
				onClick={() => setExpanded((p) => !p)}
			>
				<TableCell sx={{ width: 40, px: 1 }}>
					<IconButton size='small'>
						{expanded ? (
							<KeyboardArrowUpIcon />
						) : (
							<KeyboardArrowDownIcon />
						)}
					</IconButton>
				</TableCell>

				<TableCell>
					<Typography variant='body2' fontWeight={600}>
						#{order.id}
					</Typography>
				</TableCell>

				<TableCell>
					<Chip
						label={ORDER_STATUS_LABEL[order.status]}
						size='small'
						color={
							ORDER_STATUS_COLOR[order.status] as
								| 'info'
								| 'warning'
								| 'secondary'
								| 'primary'
								| 'success'
								| 'error'
						}
					/>
				</TableCell>

				<TableCell>
					<Box
						sx={{
							display: 'flex',
							alignItems: 'center',
							gap: 0.5,
						}}
					>
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
							{order.delivery_type === 'delivery'
								? 'Доставка'
								: 'Самовывоз'}
						</Typography>
					</Box>
				</TableCell>

				<TableCell sx={{ maxWidth: 250 }}>
					<Typography variant='body2' color='text.secondary' noWrap>
						{itemsSummary || '-'}
					</Typography>
				</TableCell>

				<TableCell align='right'>
					<Typography variant='body2' fontWeight={600}>
						{Number(order.total_price).toLocaleString('ru-RU')} ₽
					</Typography>
				</TableCell>

				<TableCell>
					<Typography variant='caption' color='text.secondary'>
						{formatDate(order.created_at)}
					</Typography>
				</TableCell>

				<TableCell
					align='right'
					onClick={(e) => e.stopPropagation()}
				>
					<Box
						sx={{
							display: 'flex',
							gap: 0.25,
							justifyContent: 'flex-end',
						}}
					>
						{canAssign && (
							<Tooltip content='Назначить курьера'>
								<IconButton
									size='small'
									onClick={() => onAssign(order)}
									sx={{ color: 'primary.main' }}
								>
									<PersonAddOutlinedIcon fontSize='small' />
								</IconButton>
							</Tooltip>
						)}
						{canCancel && (
							<Tooltip content='Отменить заказ'>
								<IconButton
									size='small'
									onClick={() => onCancel(order)}
									sx={{ color: 'error.main' }}
								>
									<CancelOutlinedIcon fontSize='small' />
								</IconButton>
							</Tooltip>
						)}
					</Box>
				</TableCell>
			</TableRow>

			<TableRow>
				<TableCell
					colSpan={8}
					sx={{
						py: 0,
						borderBottom: expanded ? undefined : 'none',
					}}
				>
					<Collapse in={expanded} timeout='auto' unmountOnExit>
						<Box sx={{ py: 2, px: 1 }}>
							<Typography
								variant='subtitle2'
								fontWeight={600}
								sx={{ mb: 1 }}
							>
								Состав заказа
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
									<Typography
										variant='body2'
										color='text.secondary'
									>
										{Number(item.subtotal).toLocaleString(
											'ru-RU'
										)}{' '}
										₽
									</Typography>
								</Box>
							))}

							<Divider sx={{ my: 1.5 }} />

							<Box
								sx={{
									display: 'flex',
									flexWrap: 'wrap',
									gap: 3,
								}}
							>
								<Typography
									variant='body2'
									color='text.secondary'
								>
									Клиент ID:{' '}
									<b>{order.customer_id}</b>
								</Typography>
								<Typography
									variant='body2'
									color='text.secondary'
								>
									Компания ID:{' '}
									<b>{order.company_id}</b>
								</Typography>
								<Typography
									variant='body2'
									color='text.secondary'
								>
									Точка ID:{' '}
									<b>{order.outlet_id}</b>
								</Typography>
								{order.courier_id && (
									<Typography
										variant='body2'
										color='text.secondary'
									>
										Курьер ID:{' '}
										<b>{order.courier_id}</b>
									</Typography>
								)}
							</Box>

							{order.delivery_address && (
								<Typography
									variant='body2'
									color='text.secondary'
									sx={{ mt: 1 }}
								>
									Адрес доставки:{' '}
									{order.delivery_address.address}
									{order.delivery_address.apartment &&
										`, кв. ${order.delivery_address.apartment}`}
									{order.delivery_address.floor &&
										`, ${order.delivery_address.floor} эт.`}
									{order.delivery_address.entrance &&
										`, подъезд ${order.delivery_address.entrance}`}
								</Typography>
							)}

							{order.comment && (
								<Typography
									variant='body2'
									color='text.secondary'
									sx={{ mt: 1 }}
								>
									Комментарий: {order.comment}
								</Typography>
							)}

							{order.status_history.length > 0 && (
								<>
									<Divider sx={{ my: 1.5 }} />
									<Typography
										variant='subtitle2'
										fontWeight={600}
										sx={{ mb: 0.5 }}
									>
										История статусов
									</Typography>
									{order.status_history.map((h, i) => (
										<Typography
											key={i}
											variant='caption'
											color='text.secondary'
											sx={{ display: 'block' }}
										>
											{formatDate(h.changed_at)} -{' '}
											{h.status} (ID: {h.changed_by})
										</Typography>
									))}
								</>
							)}
						</Box>
					</Collapse>
				</TableCell>
			</TableRow>
		</>
	);
}
