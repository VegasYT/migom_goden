export type OrderStatus =
	| 'new'
	| 'assigned'
	| 'assembling'
	| 'ready_for_pickup'
	| 'in_delivery'
	| 'delivered'
	| 'cancelled'
	| 'received';

export type DeliveryType = 'delivery' | 'pickup';

export interface OrderItem {
	id: number;
	catalog_item_id: number;
	name: string;
	price: string;
	quantity: number;
	subtotal: string;
}

export interface StatusHistoryEntry {
	status: string;
	changed_at: string;
	changed_by: number;
}

export interface DeliveryAddress {
	id: number;
	customer_id: number;
	label: string;
	address: string;
	apartment: string | null;
	floor: number | null;
	entrance: number | null;
	intercom: string | null;
	latitude: number | null;
	longitude: number | null;
	is_active: boolean;
	created_at: string;
}

export interface Order {
	id: number;
	customer_id: number;
	company_id: number;
	outlet_id: number;
	courier_id: number | null;
	status: OrderStatus;
	delivery_type: DeliveryType;
	delivery_address: DeliveryAddress | null;
	total_price: string;
	comment: string | null;
	customer_payment_method_id: number;
	delivery_time: number | null;
	leave_at_door: boolean;
	created_at: string;
	updated_at: string;
	items: OrderItem[];
	status_history: StatusHistoryEntry[];
}

export interface OrdersListResponse {
	items: Order[];
	total: number;
}

export type SortField = 'created_at' | 'total_price' | 'id';
export type SortOrder = 'asc' | 'desc';

export interface OrdersListParams {
	offset?: number;
	limit?: number;
	status?: OrderStatus;
	outlet_id?: number;
	outlet_ids?: number[];
	search?: string;
	date_from?: string;
	date_to?: string;
	sort_by?: SortField;
	sort_order?: SortOrder;
}

export type MovementType = 'walk' | 'scooter' | 'car';

export interface Courier {
	id: number;
	user_id: number;
	is_blocked: boolean;
	type_movement: MovementType | null;
	radius_km: number;
	zone_latitude: number | null;
	zone_longitude: number | null;
	current_latitude: number | null;
	current_longitude: number | null;
	location_updated_at: string | null;
}

export interface CouriersListResponse {
	items: Courier[];
	total: number;
}

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
	new: 'Новый',
	assigned: 'Назначен',
	assembling: 'Сборка',
	ready_for_pickup: 'Готов',
	in_delivery: 'Доставляется',
	delivered: 'Доставлен',
	cancelled: 'Отменён',
	received: 'Получен',
};

export const ORDER_STATUS_COLOR: Record<OrderStatus, string> = {
	new: 'info',
	assigned: 'warning',
	assembling: 'warning',
	ready_for_pickup: 'secondary',
	in_delivery: 'primary',
	delivered: 'success',
	cancelled: 'error',
	received: 'success',
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
