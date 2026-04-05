export type OrderStatus =
	| 'new'
	| 'assigned'
	| 'assembling'
	| 'ready_for_pickup'
	| 'in_delivery'
	| 'delivered'
	| 'cancelled'
	| 'received';

export type SortField = 'created_at' | 'total_price';
export type SortOrder = 'asc' | 'desc';
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

export interface OrderListResponse {
	items: Order[];
	total: number;
}

export interface OrdersFilter {
	offset?: number;
	limit?: number;
	status?: OrderStatus;
	date_from?: string;
	date_to?: string;
	sort_by?: SortField;
	sort_order?: SortOrder;
}
