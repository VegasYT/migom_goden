import {
	Table,
	TableBody,
	TableCell,
	TableContainer,
	TableHead,
	TableRow,
	Chip,
	Typography,
} from '@mui/material';
import type { Outlet } from '../types';

function formatTime(time: string) {
	return time.slice(0, 5);
}

interface Props {
	outlets: Outlet[];
}

export function CompanyOutletsList({ outlets }: Props) {
	if (outlets.length === 0) {
		return (
			<Typography variant='body2' color='text.secondary' sx={{ py: 3 }}>
				У компании нет торговых точек.
			</Typography>
		);
	}

	return (
		<TableContainer>
			<Table>
				<TableHead>
					<TableRow>
						<TableCell>Название</TableCell>
						<TableCell>Адрес</TableCell>
						<TableCell>Часы работы</TableCell>
						<TableCell>Стоимость доставки</TableCell>
						<TableCell>Статус</TableCell>
					</TableRow>
				</TableHead>
				<TableBody>
					{outlets.map((outlet) => (
						<TableRow key={outlet.id}>
							<TableCell>
								<Typography variant='body2' fontWeight={500}>
									{outlet.name}
								</Typography>
							</TableCell>
							<TableCell>
								<Typography variant='body2' color='text.secondary'>
									{outlet.address}
								</Typography>
							</TableCell>
							<TableCell>
								<Typography variant='body2' color='text.secondary'>
									{formatTime(outlet.opens_at)} –{' '}
									{formatTime(outlet.closes_at)}
								</Typography>
							</TableCell>
							<TableCell>
								<Typography variant='body2' color='text.secondary'>
									{outlet.delivery_fee} ₽
									{outlet.free_delivery_from != null && (
										<>
											{' '}
											(бесп. от {outlet.free_delivery_from} ₽)
										</>
									)}
								</Typography>
							</TableCell>
							<TableCell>
								<Chip
									label={outlet.is_active ? 'Активна' : 'Неактивна'}
									size='small'
									color={outlet.is_active ? 'success' : 'default'}
								/>
							</TableCell>
						</TableRow>
					))}
				</TableBody>
			</Table>
		</TableContainer>
	);
}
