import {
	Box,
	TextField,
	MenuItem,
	InputAdornment,
	Autocomplete,
	Chip,
} from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import type { OrderStatus, SortField, SortOrder } from '../types';
import { ORDER_STATUS_LABEL, ALL_STATUSES } from '../types';
import type { Company, Outlet } from '@features/companies';

const SORT_FIELD_LABEL: Record<SortField, string> = {
	created_at: 'По дате',
	total_price: 'По сумме',
	id: 'По ID',
};

interface Props {
	search: string;
	status: OrderStatus | '';
	dateFrom: string;
	dateTo: string;
	sortBy: SortField;
	sortOrder: SortOrder;
	companies: Company[];
	selectedCompanyIds: number[];
	outlets: Outlet[];
	outletsLoading: boolean;
	selectedOutletIds: number[];
	onSearchChange: (value: string) => void;
	onStatusChange: (status: OrderStatus | '') => void;
	onDateFromChange: (value: string) => void;
	onDateToChange: (value: string) => void;
	onSortByChange: (value: SortField) => void;
	onSortOrderChange: (value: SortOrder) => void;
	onCompaniesChange: (ids: number[]) => void;
	onOutletsChange: (ids: number[]) => void;
}

export function OrderFilters({
	search,
	status,
	dateFrom,
	dateTo,
	sortBy,
	sortOrder,
	companies,
	selectedCompanyIds,
	outlets,
	outletsLoading,
	selectedOutletIds,
	onSearchChange,
	onStatusChange,
	onDateFromChange,
	onDateToChange,
	onSortByChange,
	onSortOrderChange,
	onCompaniesChange,
	onOutletsChange,
}: Props) {
	const selectedCompanies = companies.filter((c) =>
		selectedCompanyIds.includes(c.id)
	);
	const selectedOutlets = outlets.filter((o) =>
		selectedOutletIds.includes(o.id)
	);

	return (
		<Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mb: 3 }}>
			<Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
				<TextField
					placeholder='Поиск по заказам'
					value={search}
					onChange={(e) => onSearchChange(e.target.value)}
					size='small'
					sx={{ minWidth: 240 }}
					slotProps={{
						input: {
							startAdornment: (
								<InputAdornment position='start'>
									<SearchIcon
										sx={{
											fontSize: 20,
											color: 'text.secondary',
										}}
									/>
								</InputAdornment>
							),
						},
					}}
				/>

				<TextField
					select
					label='Статус'
					value={status}
					onChange={(e) =>
						onStatusChange(e.target.value as OrderStatus | '')
					}
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
				/>

				<TextField
					label='Дата до'
					type='date'
					value={dateTo}
					onChange={(e) => onDateToChange(e.target.value)}
					size='small'
					slotProps={{ inputLabel: { shrink: true } }}
				/>

				<TextField
					select
					label='Сортировка'
					value={sortBy}
					onChange={(e) =>
						onSortByChange(e.target.value as SortField)
					}
					size='small'
					sx={{ minWidth: 140 }}
				>
					{(Object.keys(SORT_FIELD_LABEL) as SortField[]).map(
						(f) => (
							<MenuItem key={f} value={f}>
								{SORT_FIELD_LABEL[f]}
							</MenuItem>
						)
					)}
				</TextField>

				<TextField
					select
					label='Порядок'
					value={sortOrder}
					onChange={(e) =>
						onSortOrderChange(e.target.value as SortOrder)
					}
					size='small'
					sx={{ minWidth: 120 }}
				>
					<MenuItem value='desc'>По убыванию</MenuItem>
					<MenuItem value='asc'>По возрастанию</MenuItem>
				</TextField>
			</Box>

			<Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
				<Autocomplete
					multiple
					size='small'
					sx={{ minWidth: 280 }}
					options={companies}
					value={selectedCompanies}
					getOptionLabel={(o) => o.name}
					isOptionEqualToValue={(a, b) => a.id === b.id}
					onChange={(_, value) =>
						onCompaniesChange(value.map((c) => c.id))
					}
					renderInput={(params) => (
						<TextField {...params} label='Компании' />
					)}
					renderTags={(value, getTagProps) =>
						value.map((option, index) => (
							<Chip
								{...getTagProps({ index })}
								key={option.id}
								label={option.name}
								size='small'
							/>
						))
					}
				/>

				<Autocomplete
					multiple
					size='small'
					sx={{ minWidth: 280 }}
					options={outlets}
					value={selectedOutlets}
					loading={outletsLoading}
					disabled={selectedCompanyIds.length === 0}
					getOptionLabel={(o) => `${o.name} - ${o.address}`}
					isOptionEqualToValue={(a, b) => a.id === b.id}
					onChange={(_, value) =>
						onOutletsChange(value.map((o) => o.id))
					}
					renderInput={(params) => (
						<TextField
							{...params}
							label='Торговые точки'
							placeholder={
								selectedCompanyIds.length === 0
									? 'Сначала выберите компанию'
									: undefined
							}
						/>
					)}
					renderTags={(value, getTagProps) =>
						value.map((option, index) => (
							<Chip
								{...getTagProps({ index })}
								key={option.id}
								label={option.name}
								size='small'
							/>
						))
					}
				/>
			</Box>
		</Box>
	);
}
