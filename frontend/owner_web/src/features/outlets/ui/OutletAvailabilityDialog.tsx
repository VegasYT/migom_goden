import { useState } from 'react';
import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogActions,
	Button,
	List,
	ListItem,
	ListItemText,
	ListItemAvatar,
	Avatar,
	Switch,
	Box,
	Typography,
	CircularProgress,
	TextField,
} from '@mui/material';
import { useMenu } from '@features/menu';
import { useItemsAvailability } from '../api/useItemsAvailability';
import { useSetItemAvailability } from '../api/useSetItemAvailability';
import type { Outlet, ItemAvailabilityWithInfo } from '../types';

interface ItemRowProps {
	item: { id: number; name: string; price: string; photo_url?: string | null };
	outletId: number;
	availabilityInfo: ItemAvailabilityWithInfo | undefined;
}

function ItemRow({ item, outletId, availabilityInfo }: ItemRowProps) {
	const setAvailability = useSetItemAvailability();
	const isAvailable = availabilityInfo?.is_available ?? false;
	const [stockCount, setStockCount] = useState<string>(
		availabilityInfo?.stock_count != null ? String(availabilityInfo.stock_count) : '',
	);

	return (
		<ListItem
			secondaryAction={
				<Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
					{isAvailable && (
						<TextField
							size='small'
							placeholder='∞'
							value={stockCount}
							onChange={(e) => {
								const v = e.target.value.replace(/[^0-9]/g, '');
								setStockCount(v);
							}}
							onBlur={() => {
								setAvailability.mutate({
									outletId,
									itemId: item.id,
									dto: {
										is_available: true,
										stock_count: stockCount === '' ? null : Number(stockCount),
									},
								});
							}}
							sx={{ width: 72 }}
							slotProps={{
								htmlInput: { inputMode: 'numeric', style: { textAlign: 'center' } },
							}}
						/>
					)}
					<Switch
						size='small'
						checked={isAvailable}
						disabled={setAvailability.isPending}
						onChange={() =>
							setAvailability.mutate({
								outletId,
								itemId: item.id,
								dto: {
									is_available: !isAvailable,
									stock_count: isAvailable
										? null
										: stockCount === ''
											? null
											: Number(stockCount),
								},
							})
						}
					/>
				</Box>
			}
		>
			{item.photo_url && (
				<ListItemAvatar sx={{ minWidth: 48 }}>
					<Avatar
						variant='rounded'
						src={item.photo_url}
						alt={item.name}
						sx={{ width: 36, height: 36 }}
					/>
				</ListItemAvatar>
			)}
			<ListItemText
				primary={item.name}
				secondary={`${item.price} ₽`}
				primaryTypographyProps={{ variant: 'body2' }}
				secondaryTypographyProps={{ variant: 'caption' }}
			/>
		</ListItem>
	);
}

interface Props {
	open: boolean;
	onClose: () => void;
	outlet: Outlet;
	companyId: number;
}

export function OutletAvailabilityDialog({
	open,
	onClose,
	outlet,
	companyId,
}: Props) {
	const { data: companyMenu, isLoading: menuLoading } = useMenu(companyId);
	const { data: availability, isLoading: availabilityLoading } =
		useItemsAvailability(open ? outlet.id : null);

	const isLoading = menuLoading || availabilityLoading;

	// Map catalog_item_id → availability info
	const availabilityMap = new Map(
		availability?.map((a) => [a.catalog_item_id, a]) ?? [],
	);

	const categories =
		companyMenu?.categories.filter((cat) => cat.items.length > 0) ?? [];

	return (
		<Dialog open={open} onClose={onClose} maxWidth='sm' fullWidth>
			<DialogTitle>Товары в точке - {outlet.name}</DialogTitle>

			<DialogContent dividers sx={{ p: 0 }}>
				{isLoading ? (
					<Box
						sx={{
							display: 'flex',
							justifyContent: 'center',
							alignItems: 'center',
							py: 5,
						}}
					>
						<CircularProgress />
					</Box>
				) : categories.length === 0 ? (
					<Box
						sx={{
							display: 'flex',
							justifyContent: 'center',
							alignItems: 'center',
							py: 5,
						}}
					>
						<Typography variant='body2' color='text.secondary'>
							Меню пусто
						</Typography>
					</Box>
				) : (
					<List disablePadding>
						{categories.map((category) => (
							<Box key={category.id}>
								<ListItem sx={{ bgcolor: 'action.hover', py: 0.75 }}>
									<ListItemText
										primary={
											<Typography variant='caption' fontWeight={600} color='text.secondary'>
												{category.name}
											</Typography>
										}
									/>
								</ListItem>

								{category.items.map((item) => (
									<ItemRow
										key={item.id}
										item={item}
										outletId={outlet.id}
										availabilityInfo={availabilityMap.get(item.id)}
									/>
								))}
							</Box>
						))}
					</List>
				)}
			</DialogContent>

			<DialogActions sx={{ px: 3, pb: 2.5 }}>
				<Button onClick={onClose} color='inherit'>
					Закрыть
				</Button>
			</DialogActions>
		</Dialog>
	);
}
