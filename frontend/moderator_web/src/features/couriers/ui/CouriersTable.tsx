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
import BlockOutlinedIcon from '@mui/icons-material/BlockOutlined';
import LockOpenOutlinedIcon from '@mui/icons-material/LockOpenOutlined';
import { Tooltip } from '@shared/ui/tooltip';
import type { Courier, Shift } from '../types';
import { MOVEMENT_LABEL } from '../types';

function timeAgo(iso: string): string {
	const diff = Date.now() - new Date(iso).getTime();
	const mins = Math.floor(diff / 60_000);
	if (mins < 1) return 'только что';
	if (mins < 60) return `${mins} мин назад`;
	const hours = Math.floor(mins / 60);
	if (hours < 24) return `${hours} ч назад`;
	const days = Math.floor(hours / 24);
	return `${days} дн назад`;
}

interface Props {
	couriers: Courier[];
	shifts: Map<number, Shift>;
	onToggleBlock: (courier: Courier) => void;
	blockPending?: boolean;
}

export function CouriersTable({
	couriers,
	shifts,
	onToggleBlock,
	blockPending,
}: Props) {
	return (
		<TableContainer>
			<Table>
				<TableHead>
					<TableRow>
						<TableCell>ID</TableCell>
						<TableCell>User ID</TableCell>
						<TableCell>Тип</TableCell>
						<TableCell>Радиус</TableCell>
						<TableCell>Смена</TableCell>
						<TableCell>Статус</TableCell>
						<TableCell align='right'>Действия</TableCell>
					</TableRow>
				</TableHead>
				<TableBody>
					{couriers.map((courier) => {
						const shift = shifts.get(courier.id);
						const isOnline = !!shift;

						return (
							<TableRow key={courier.id} hover>
								<TableCell>
									<Typography
										variant='body2'
										fontWeight={600}
									>
										#{courier.id}
									</Typography>
								</TableCell>
								<TableCell>
									<Typography
										variant='body2'
										color='text.secondary'
									>
										{courier.user_id}
									</Typography>
								</TableCell>
								<TableCell>
									<Typography
										variant='body2'
										color='text.secondary'
									>
										{courier.type_movement
											? MOVEMENT_LABEL[
													courier.type_movement
												]
											: '-'}
									</Typography>
								</TableCell>
								<TableCell>
									<Typography
										variant='body2'
										color='text.secondary'
									>
										{courier.radius_km} км
									</Typography>
								</TableCell>
								<TableCell>
									<Box
										sx={{
											display: 'flex',
											alignItems: 'center',
											gap: 0.75,
										}}
									>
										<Box
											sx={{
												width: 8,
												height: 8,
												borderRadius: '50%',
												bgcolor: isOnline
													? 'success.main'
													: 'text.disabled',
												flexShrink: 0,
											}}
										/>
										<Typography
											variant='body2'
											color='text.secondary'
										>
											{isOnline
												? `В сети · ${timeAgo(shift.started_at)}`
												: 'Не в смене'}
										</Typography>
									</Box>
								</TableCell>
								<TableCell>
									<Chip
										label={
											courier.is_blocked
												? 'Заблокирован'
												: 'Активен'
										}
										size='small'
										color={
											courier.is_blocked
												? 'error'
												: 'success'
										}
									/>
								</TableCell>
								<TableCell align='right'>
									<Tooltip
										content={
											courier.is_blocked
												? 'Разблокировать'
												: 'Заблокировать'
										}
									>
										<IconButton
											size='small'
											disabled={blockPending}
											onClick={() =>
												onToggleBlock(courier)
											}
											sx={{
												color: courier.is_blocked
													? 'success.main'
													: 'warning.main',
											}}
										>
											{courier.is_blocked ? (
												<LockOpenOutlinedIcon fontSize='small' />
											) : (
												<BlockOutlinedIcon fontSize='small' />
											)}
										</IconButton>
									</Tooltip>
								</TableCell>
							</TableRow>
						);
					})}
				</TableBody>
			</Table>
		</TableContainer>
	);
}
