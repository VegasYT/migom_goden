import {
	Accordion,
	AccordionSummary,
	AccordionDetails,
	Typography,
	Box,
	Chip,
	Avatar,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import type { CompanyMenu } from '../types';

interface Props {
	menu: CompanyMenu;
}

export function CompanyMenuView({ menu }: Props) {
	const categories = menu.categories.filter((c) => c.items.length > 0);

	if (categories.length === 0) {
		return (
			<Typography variant='body2' color='text.secondary' sx={{ py: 3 }}>
				Меню пусто.
			</Typography>
		);
	}

	return (
		<Box>
			{categories.map((category) => (
				<Accordion key={category.id} variant='outlined' defaultExpanded>
					<AccordionSummary expandIcon={<ExpandMoreIcon />}>
						<Box
							sx={{
								display: 'flex',
								alignItems: 'center',
								gap: 1,
							}}
						>
							<Typography variant='body1'>
								{category.emoji}
							</Typography>
							<Typography variant='subtitle2' fontWeight={600}>
								{category.name}
							</Typography>
							<Chip
								label={category.items.length}
								size='small'
								sx={{ height: 20, fontSize: 11 }}
							/>
							{!category.is_active && (
								<Chip
									label='Неактивна'
									size='small'
									color='default'
									sx={{ height: 20, fontSize: 11 }}
								/>
							)}
						</Box>
					</AccordionSummary>
					<AccordionDetails sx={{ pt: 0 }}>
						{category.items.map((item) => (
							<Box
								key={item.id}
								sx={{
									display: 'flex',
									alignItems: 'center',
									gap: 2,
									py: 1,
									borderBottom: '1px solid',
									borderColor: 'divider',
									'&:last-child': { borderBottom: 'none' },
								}}
							>
								{item.photo_url ? (
									<Avatar
										src={item.photo_url}
										alt={item.name}
										variant='rounded'
										sx={{ width: 48, height: 48 }}
									/>
								) : (
									<Avatar
										variant='rounded'
										sx={{
											width: 48,
											height: 48,
											bgcolor: 'action.hover',
											color: 'text.disabled',
											fontSize: 12,
										}}
									>
										Нет
									</Avatar>
								)}
								<Box sx={{ flex: 1, minWidth: 0 }}>
									<Box
										sx={{
											display: 'flex',
											alignItems: 'center',
											gap: 1,
										}}
									>
										<Typography
											variant='body2'
											fontWeight={500}
											noWrap
										>
											{item.name}
										</Typography>
										{!item.is_active && (
											<Chip
												label='Неактивна'
												size='small'
												color='default'
												sx={{ height: 18, fontSize: 10 }}
											/>
										)}
									</Box>
									{item.description && (
										<Typography
											variant='caption'
											color='text.secondary'
											noWrap
											sx={{ display: 'block' }}
										>
											{item.description}
										</Typography>
									)}
								</Box>
								<Typography
									variant='body2'
									fontWeight={600}
									sx={{ flexShrink: 0 }}
								>
									{Number(item.price).toLocaleString('ru-RU')} ₽
								</Typography>
							</Box>
						))}
					</AccordionDetails>
				</Accordion>
			))}
		</Box>
	);
}
