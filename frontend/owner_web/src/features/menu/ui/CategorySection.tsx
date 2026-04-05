import {
	Box,
	Typography,
	Chip,
	IconButton,
	Button,
	Accordion,
	AccordionSummary,
	AccordionDetails,
	Divider,
	Tooltip,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import EditOutlinedIcon from '@mui/icons-material/EditOutlined';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import AddIcon from '@mui/icons-material/Add';
import RestaurantIcon from '@mui/icons-material/Restaurant';
import { useDeleteMenuItem } from '../api/useDeleteMenuItem';
import type { MenuCategory, MenuItem } from '../types';

interface Props {
	category: MenuCategory;
	companyId: number;
	onAddItem: (categoryId: number) => void;
	onEditItem: (item: MenuItem) => void;
}

export function CategorySection({ category, companyId, onAddItem, onEditItem }: Props) {
	const deleteItem = useDeleteMenuItem();

	return (
		<Accordion
			defaultExpanded
			disableGutters
			elevation={0}
			sx={{
				bgcolor: 'background.paper',
				border: '1px solid',
				borderColor: 'divider',
				borderRadius: '12px !important',
				'&:before': { display: 'none' },
				overflow: 'hidden',
			}}
		>
			<AccordionSummary
				expandIcon={<ExpandMoreIcon sx={{ color: 'text.secondary' }} />}
				sx={{
					px: 2.5,
					py: 0.5,
					'& .MuiAccordionSummary-content': {
						alignItems: 'center',
						gap: 1.5,
						my: 1.5,
					},
				}}
			>
				<Typography fontWeight={600} color='text.primary'>
					{category.emoji} {category.name}
				</Typography>
				<Chip
					label={category.items.length}
					size='small'
					sx={{
						height: 20,
						fontSize: 11,
						bgcolor: 'action.selected',
						color: 'text.secondary',
					}}
				/>

				<Box
					sx={{ ml: 'auto', display: 'flex', alignItems: 'center', gap: 0.5 }}
					onClick={(e) => e.stopPropagation()}
				>
					<Button
						size='small'
						startIcon={<AddIcon />}
						onClick={() => onAddItem(category.id)}
						sx={{ fontSize: 13, fontWeight: 500 }}
					>
						Позиция
					</Button>
				</Box>
			</AccordionSummary>

			<AccordionDetails sx={{ p: 0 }}>
				<Divider />

				{category.items.length === 0 ? (
					<Typography
						variant='body2'
						color='text.secondary'
						sx={{ py: 3, textAlign: 'center' }}
					>
						Нет позиций - нажмите «Позиция» чтобы добавить первую
					</Typography>
				) : (
					category.items.map((item, idx) => (
						<Box key={item.id}>
							<Box
								sx={{
									display: 'flex',
									alignItems: 'center',
									gap: 2,
									px: 2.5,
									py: 1.75,
								}}
							>
								{/* Иконка / фото */}
								<Box
									sx={{
										width: 40,
										height: 40,
										borderRadius: 1.5,
										bgcolor: item.photo_url ? undefined : 'action.hover',
										backgroundImage: item.photo_url
											? `url(${item.photo_url})`
											: undefined,
										backgroundSize: 'cover',
										backgroundPosition: 'center',
										display: 'flex',
										alignItems: 'center',
										justifyContent: 'center',
										flexShrink: 0,
									}}
								>
									{!item.photo_url && (
										<RestaurantIcon sx={{ fontSize: 18, color: 'text.secondary' }} />
									)}
								</Box>

								{/* Название + описание */}
								<Box sx={{ flex: 1, minWidth: 0 }}>
									<Typography variant='body2' fontWeight={500} noWrap>
										{item.name}
									</Typography>
									{item.description && (
										<Typography
											variant='caption'
											color='text.secondary'
											noWrap
											display='block'
										>
											{item.description}
										</Typography>
									)}
								</Box>

								{/* Цена */}
								<Typography
									variant='body2'
									fontWeight={600}
									color='text.primary'
									sx={{ flexShrink: 0 }}
								>
									{item.price} ₽
								</Typography>

								{/* Статус */}
								<Chip
									label={item.is_active ? 'Активен' : 'Скрыт'}
									size='small'
									sx={{
										height: 22,
										fontSize: 11,
										flexShrink: 0,
										bgcolor: item.is_active
											? 'rgba(74, 222, 128, 0.12)'
											: 'action.selected',
										color: item.is_active ? 'primary.main' : 'text.secondary',
									}}
								/>

								{/* Действия */}
								<Box sx={{ display: 'flex', gap: 0.25, flexShrink: 0 }}>
									<Tooltip title='Редактировать'>
										<IconButton size='small' onClick={() => onEditItem(item)}>
											<EditOutlinedIcon sx={{ fontSize: 16 }} />
										</IconButton>
									</Tooltip>
									<Tooltip title='Удалить'>
										<IconButton
											size='small'
											onClick={() =>
												deleteItem.mutate({ companyId, itemId: item.id })
											}
											disabled={deleteItem.isPending}
										>
											<DeleteOutlineIcon sx={{ fontSize: 16 }} />
										</IconButton>
									</Tooltip>
								</Box>
							</Box>
							{idx < category.items.length - 1 && <Divider />}
						</Box>
					))
				)}
			</AccordionDetails>
		</Accordion>
	);
}
