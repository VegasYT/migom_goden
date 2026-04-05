import {
	Table,
	TableBody,
	TableCell,
	TableContainer,
	TableHead,
	TableRow,
	Chip,
	IconButton,
	Typography,
	Box,
	Switch,
} from '@mui/material';
import EditOutlinedIcon from '@mui/icons-material/EditOutlined';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import { Tooltip } from '@shared/ui/tooltip';
import type { Category } from '../types';

interface Props {
	categories: Category[];
	onEdit: (category: Category) => void;
	onDelete: (category: Category) => void;
	onToggleActive: (category: Category) => void;
	togglePending?: boolean;
}

export function CategoriesTable({
	categories,
	onEdit,
	onDelete,
	onToggleActive,
	togglePending,
}: Props) {
	return (
		<TableContainer>
			<Table>
				<TableHead>
					<TableRow>
						<TableCell sx={{ width: 60 }}>Эмодзи</TableCell>
						<TableCell>Название</TableCell>
						<TableCell sx={{ width: 120 }}>Порядок</TableCell>
						<TableCell sx={{ width: 120 }}>Статус</TableCell>
						<TableCell sx={{ width: 100 }}>Активна</TableCell>
						<TableCell align='right' sx={{ width: 100 }}>
							Действия
						</TableCell>
					</TableRow>
				</TableHead>
				<TableBody>
					{categories.map((category) => (
						<TableRow key={category.id} hover>
							<TableCell>
								<Typography variant='h6'>{category.emoji}</Typography>
							</TableCell>
							<TableCell>
								<Typography variant='body2' fontWeight={500}>
									{category.name}
								</Typography>
							</TableCell>
							<TableCell>
								<Typography variant='body2' color='text.secondary'>
									{category.sort_order}
								</Typography>
							</TableCell>
							<TableCell>
								<Chip
									label={category.is_active ? 'Активна' : 'Неактивна'}
									size='small'
									color={category.is_active ? 'success' : 'default'}
								/>
							</TableCell>
							<TableCell>
								<Switch
									size='small'
									checked={category.is_active}
									disabled={togglePending}
									onChange={() => onToggleActive(category)}
								/>
							</TableCell>
							<TableCell align='right'>
								<Box
									sx={{
										display: 'flex',
										gap: 0.25,
										justifyContent: 'flex-end',
									}}
								>
									<Tooltip content='Редактировать'>
										<IconButton
											size='small'
											onClick={() => onEdit(category)}
											sx={{ color: 'text.secondary' }}
										>
											<EditOutlinedIcon fontSize='small' />
										</IconButton>
									</Tooltip>
									<Tooltip content='Удалить'>
										<IconButton
											size='small'
											onClick={() => onDelete(category)}
											sx={{ color: 'error.main' }}
										>
											<DeleteOutlineIcon fontSize='small' />
										</IconButton>
									</Tooltip>
								</Box>
							</TableCell>
						</TableRow>
					))}
				</TableBody>
			</Table>
		</TableContainer>
	);
}
