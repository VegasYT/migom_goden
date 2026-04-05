import { Box, TextField, MenuItem } from '@mui/material';
import { ALL_STATUSES, ORDER_STATUS_LABEL } from '../lib/orderStatus';
import type { OrderStatus, SortField, SortOrder } from '../types';

interface Props {
	status: OrderStatus | '';
	dateFrom: string;
	dateTo: string;
	sortBy: SortField;
	sortOrder: SortOrder;
	onStatusChange: (v: OrderStatus | '') => void;
	onDateFromChange: (v: string) => void;
	onDateToChange: (v: string) => void;
	onSortByChange: (v: SortField) => void;
	onSortOrderChange: (v: SortOrder) => void;
}

export function OrderFilters({
	status,
	dateFrom,
	dateTo,
	sortBy,
	sortOrder,
	onStatusChange,
	onDateFromChange,
	onDateToChange,
	onSortByChange,
	onSortOrderChange,
}: Props) {
	return (
		<Box
			sx={{
				display: 'flex',
				flexWrap: 'wrap',
				gap: 2,
				mb: 3,
			}}
		>
			<TextField
				select
				label='Статус'
				value={status}
				onChange={(e) => onStatusChange(e.target.value as OrderStatus | '')}
				size='small'
				sx={{ minWidth: 160 }}
			>
				<MenuItem value=''>Все</MenuItem>
				{ALL_STATUSES.map((s) => (
					<MenuItem key={s} value={s}>
						{ORDER_STATUS_LABEL[s]}
					</MenuItem>
				))}
			</TextField>

			<TextField
				label='Дата от'
				type='date'
				value={dateFrom}
				onChange={(e) => onDateFromChange(e.target.value)}
				size='small'
				slotProps={{ inputLabel: { shrink: true } }}
				sx={{ minWidth: 150 }}
			/>

			<TextField
				label='Дата до'
				type='date'
				value={dateTo}
				onChange={(e) => onDateToChange(e.target.value)}
				size='small'
				slotProps={{ inputLabel: { shrink: true } }}
				sx={{ minWidth: 150 }}
			/>

			<TextField
				select
				label='Сортировка'
				value={sortBy}
				onChange={(e) => onSortByChange(e.target.value as SortField)}
				size='small'
				sx={{ minWidth: 150 }}
			>
				<MenuItem value='created_at'>По дате</MenuItem>
				<MenuItem value='total_price'>По сумме</MenuItem>
			</TextField>

			<TextField
				select
				label='Порядок'
				value={sortOrder}
				onChange={(e) => onSortOrderChange(e.target.value as SortOrder)}
				size='small'
				sx={{ minWidth: 130 }}
			>
				<MenuItem value='desc'>
					{sortBy === 'created_at' ? 'Новые' : 'Возрастание'}
				</MenuItem>
				<MenuItem value='asc'>
					{sortBy === 'created_at' ? 'Старые' : 'Убывание'}
				</MenuItem>
			</TextField>
		</Box>
	);
}
