import {
	Card,
	CardMedia,
	CardContent,
	Typography,
	Chip,
	Box,
	Button,
	Stack,
} from '@mui/material';
import BlockOutlinedIcon from '@mui/icons-material/BlockOutlined';
import LockOpenOutlinedIcon from '@mui/icons-material/LockOpenOutlined';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import type { Company } from '../types';

function formatDateTime(iso: string) {
	return new Date(iso).toLocaleString('ru-RU', {
		day: '2-digit',
		month: '2-digit',
		year: 'numeric',
		hour: '2-digit',
		minute: '2-digit',
	});
}

interface Props {
	company: Company;
	onBlock: () => void;
	onDelete: () => void;
	blockPending?: boolean;
}

export function CompanyInfoCard({
	company,
	onBlock,
	onDelete,
	blockPending,
}: Props) {
	return (
		<Card variant='outlined'>
			{company.cover_url && (
				<CardMedia
					component='img'
					height={180}
					image={company.cover_url}
					alt={company.name}
					sx={{ objectFit: 'cover' }}
				/>
			)}
			<CardContent>
				<Box
					sx={{
						display: 'flex',
						justifyContent: 'space-between',
						alignItems: 'flex-start',
						mb: 2,
					}}
				>
					<Box>
						<Typography variant='h5' fontWeight={700} gutterBottom>
							{company.name}
						</Typography>
						{company.description && (
							<Typography
								variant='body2'
								color='text.secondary'
								sx={{ mb: 1 }}
							>
								{company.description}
							</Typography>
						)}
					</Box>
					<Stack direction='row' spacing={1}>
						{company.is_blocked ? (
							<Chip label='Заблокирована' color='error' size='small' />
						) : company.is_active ? (
							<Chip label='Активна' color='success' size='small' />
						) : (
							<Chip label='Неактивна' color='default' size='small' />
						)}
					</Stack>
				</Box>

				<Stack spacing={1} sx={{ mb: 2.5 }}>
					<Typography variant='body2' color='text.secondary'>
						ID владельца: <b>{company.owner_id}</b>
					</Typography>
					<Typography variant='body2' color='text.secondary'>
						Создана: {formatDateTime(company.created_at)}
					</Typography>
					<Typography variant='body2' color='text.secondary'>
						Обновлена: {formatDateTime(company.updated_at)}
					</Typography>
				</Stack>

				<Stack direction='row' spacing={1.5}>
					{company.is_blocked ? (
						<Button
							variant='outlined'
							color='success'
							size='small'
							startIcon={<LockOpenOutlinedIcon />}
							onClick={onBlock}
							disabled={blockPending}
						>
							Разблокировать
						</Button>
					) : (
						<Button
							variant='outlined'
							color='warning'
							size='small'
							startIcon={<BlockOutlinedIcon />}
							onClick={onBlock}
							disabled={blockPending}
						>
							Заблокировать
						</Button>
					)}
					<Button
						variant='outlined'
						color='error'
						size='small'
						startIcon={<DeleteOutlineIcon />}
						onClick={onDelete}
					>
						Удалить
					</Button>
				</Stack>
			</CardContent>
		</Card>
	);
}
