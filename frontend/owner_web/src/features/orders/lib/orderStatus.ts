import type { OrderStatus } from '../types';

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
	new: 'Новый',
	assigned: 'Назначен',
	assembling: 'Сборка',
	ready_for_pickup: 'Готов к выдаче',
	in_delivery: 'В доставке',
	delivered: 'Доставлен',
	cancelled: 'Отменён',
	received: 'Получен',
};

export const ORDER_STATUS_COLOR: Record<OrderStatus, string> = {
	new: 'info',
	assigned: 'warning',
	assembling: 'warning',
	ready_for_pickup: 'success',
	in_delivery: 'primary',
	delivered: 'success',
	cancelled: 'error',
	received: 'default',
};

export const ALL_STATUSES: OrderStatus[] = [
	'new',
	'assigned',
	'assembling',
	'ready_for_pickup',
	'in_delivery',
	'delivered',
	'cancelled',
	'received',
];
