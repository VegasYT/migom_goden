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
} from '@mui/material';
import VisibilityOutlinedIcon from '@mui/icons-material/VisibilityOutlined';
import BlockOutlinedIcon from '@mui/icons-material/BlockOutlined';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import { Tooltip } from '@shared/ui/tooltip';
import type { Company } from '../types';

function formatDate(iso: string) {
	return new Date(iso).toLocaleDateString('ru-RU', {
		day: '2-digit',
		month: '2-digit',
		year: 'numeric',
	});
}

function getStatusChip(company: Company) {
	if (company.is_blocked) {
		return <Chip label='Заблокирована' size='small' color='error' />;
	}
	if (company.is_active) {
		return <Chip label='Активна' size='small' color='success' />;
	}
	return <Chip label='Неактивна' size='small' color='default' />;
}

interface Props {
	companies: Company[];
	onView: (company: Company) => void;
	onBlock: (company: Company) => void;
	onDelete: (company: Company) => void;
}

export function CompaniesTable({
	companies,
	onView,
	onBlock,
	onDelete,
}: Props) {
	return (
		<TableContainer>
			<Table>
				<TableHead>
					<TableRow>
						<TableCell>Название</TableCell>
						<TableCell>ID владельца</TableCell>
						<TableCell>Статус</TableCell>
						<TableCell>Дата создания</TableCell>
						<TableCell align='right'>Действия</TableCell>
					</TableRow>
				</TableHead>
				<TableBody>
					{companies.map((company) => (
						<TableRow
							key={company.id}
							hover
							sx={{ cursor: 'pointer' }}
							onClick={() => onView(company)}
						>
							<TableCell>
								<Typography variant='body2' fontWeight={600}>
									{company.name}
								</Typography>
								{company.description && (
									<Typography
										variant='caption'
										color='text.secondary'
										noWrap
										sx={{ maxWidth: 300, display: 'block' }}
									>
										{company.description}
									</Typography>
								)}
							</TableCell>
							<TableCell>
								<Typography variant='body2' color='text.secondary'>
									{company.owner_id}
								</Typography>
							</TableCell>
							<TableCell>{getStatusChip(company)}</TableCell>
							<TableCell>
								<Typography variant='caption' color='text.secondary'>
									{formatDate(company.created_at)}
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
									<Tooltip content='Просмотр'>
										<IconButton
											size='small'
											onClick={() => onView(company)}
											sx={{ color: 'text.secondary' }}
										>
											<VisibilityOutlinedIcon fontSize='small' />
										</IconButton>
									</Tooltip>
									<Tooltip
										content={
											company.is_blocked
												? 'Разблокировать'
												: 'Заблокировать'
										}
									>
										<IconButton
											size='small'
											onClick={() => onBlock(company)}
											sx={{
												color: company.is_blocked
													? 'success.main'
													: 'warning.main',
											}}
										>
											<BlockOutlinedIcon fontSize='small' />
										</IconButton>
									</Tooltip>
									<Tooltip content='Удалить'>
										<IconButton
											size='small'
											onClick={() => onDelete(company)}
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
