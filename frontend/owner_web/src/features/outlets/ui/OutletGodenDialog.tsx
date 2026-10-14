import { useState } from 'react';
import {
	Alert,
	Box,
	Button,
	CircularProgress,
	Dialog,
	DialogActions,
	DialogContent,
	DialogTitle,
	Divider,
	MenuItem,
	TextField,
	Typography,
} from '@mui/material';
import { useGlobalCategories, useMenu } from '@features/menu';
import {
	useCreateItemFromDish,
	useGodenDishes,
	useGodenPoints,
	useLinkByName,
	useLinkDish,
	useSetGodenPoint,
} from '../api/useGoden';
import type { GodenDish, Outlet } from '../types';

interface Props {
	open: boolean;
	onClose: () => void;
	outlet: Outlet;
	companyId: number;
}

const NOT_LINKED = '';

export function OutletGodenDialog({ open, onClose, outlet, companyId }: Props) {
	const connected = outlet.goden_point_id !== null;
	const points = useGodenPoints(open);
	const dishes = useGodenDishes(outlet.id, open && connected);
	const { data: menu } = useMenu(open && connected ? companyId : null);
	const { data: categories } = useGlobalCategories();
	const setPoint = useSetGodenPoint(companyId);
	const linkByName = useLinkByName(outlet.id, companyId);
	const linkDish = useLinkDish(outlet.id, companyId);
	const createItem = useCreateItemFromDish(outlet.id, companyId);

	const [pointId, setPointId] = useState('');
	const [creating, setCreating] = useState<GodenDish | null>(null);
	const [categoryId, setCategoryId] = useState('');
	const [price, setPrice] = useState('');

	const items = menu?.categories.flatMap((c) => c.items) ?? [];
	const current = points.data?.find((p) => p.id === outlet.goden_point_id);

	// у блюда один товар: прежний отвязывается до привязки нового
	const changeItem = async (dish: GodenDish, value: string) => {
		if (dish.item) await linkDish.mutateAsync({ itemId: dish.item.id, dishId: null });
		if (value !== NOT_LINKED) await linkDish.mutateAsync({ itemId: Number(value), dishId: dish.id });
	};

	const submitCreate = () => {
		if (!creating) return;
		createItem.mutate(
			{ dish: creating, categoryId: Number(categoryId), price },
			{ onSuccess: () => setCreating(null) },
		);
	};

	return (
		<Dialog open={open} onClose={onClose} maxWidth='md' fullWidth>
			<DialogTitle>Goden - {outlet.name}</DialogTitle>

			<DialogContent dividers>
				{/* Точка Goden */}
				<Typography variant='subtitle2' sx={{ mb: 1 }}>
					Точка Goden
				</Typography>
				<Typography variant='body2' color='text.secondary' sx={{ mb: 2 }}>
					Наличие блюд и заказы заведения пойдут через склад этой точки. Показаны работающие точки
					Goden, которыми вы владеете.
				</Typography>
				{points.isLoading ? (
					<CircularProgress size={24} />
				) : points.isError ? (
					<Alert severity='warning'>Не удалось получить точки Goden. Попробуйте позже.</Alert>
				) : connected ? (
					<Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
						<Typography>
							{current ? `${current.company_name} - ${current.name}` : 'Подключена точка Goden'}
						</Typography>
						<Button
							color='error'
							variant='outlined'
							size='small'
							disabled={setPoint.isPending}
							onClick={() => setPoint.mutate({ outletId: outlet.id, pointId: null })}
						>
							Отключить
						</Button>
					</Box>
				) : (points.data?.length ?? 0) === 0 ? (
					<Alert severity='info'>
						У вас нет работающих точек в Goden. Создайте компанию и точку в Goden под той же учётной
						записью.
					</Alert>
				) : (
					<Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
						<TextField
							select
							size='small'
							label='Точка'
							value={pointId}
							onChange={(e) => setPointId(e.target.value)}
							sx={{ minWidth: 320 }}
						>
							{points.data!.map((p) => (
								<MenuItem key={p.id} value={p.id} disabled={p.outlet_id !== null}>
									{p.company_name} - {p.name}
									{p.outlet_id !== null ? ' (подключена к другому заведению)' : ''}
								</MenuItem>
							))}
						</TextField>
						<Button
							variant='contained'
							disabled={!pointId || setPoint.isPending}
							onClick={() => setPoint.mutate({ outletId: outlet.id, pointId })}
							sx={{ textTransform: 'none' }}
						>
							Подключить
						</Button>
					</Box>
				)}

				{/* Блюда Goden */}
				{connected && (
					<>
						<Divider sx={{ my: 2.5 }} />
						<Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
							<Typography variant='subtitle2'>Блюда Goden</Typography>
							<Button
								size='small'
								disabled={linkByName.isPending || !dishes.data}
								onClick={() => linkByName.mutate()}
								sx={{ textTransform: 'none' }}
							>
								Связать по названию
							</Button>
						</Box>
						<Typography variant='body2' color='text.secondary' sx={{ mb: 2 }}>
							Свяжите каждое блюдо точки с товаром меню: по связи товар получает наличие из Goden.
						</Typography>

						{creating && (
							<Box
								sx={{ display: 'flex', gap: 1, alignItems: 'center', flexWrap: 'wrap', mb: 2, p: 1.5,
									border: '1px solid', borderColor: 'divider', borderRadius: 2 }}
							>
								<Typography sx={{ mr: 1 }}>Новый товар "{creating.name}"</Typography>
								<TextField
									select
									size='small'
									label='Категория'
									value={categoryId}
									onChange={(e) => setCategoryId(e.target.value)}
									sx={{ minWidth: 180 }}
								>
									{(categories ?? []).map((c) => (
										<MenuItem key={c.id} value={String(c.id)}>
											{c.emoji} {c.name}
										</MenuItem>
									))}
								</TextField>
								<TextField
									size='small'
									label='Цена, ₽'
									type='number'
									value={price}
									onChange={(e) => setPrice(e.target.value)}
									sx={{ width: 120 }}
								/>
								<Button
									variant='contained'
									size='small'
									disabled={!categoryId || !(Number(price) > 0) || createItem.isPending}
									onClick={submitCreate}
									sx={{ textTransform: 'none' }}
								>
									Создать
								</Button>
								<Button size='small' color='inherit' onClick={() => setCreating(null)}>
									Отмена
								</Button>
							</Box>
						)}

						{dishes.isLoading ? (
							<CircularProgress size={24} />
						) : dishes.isError ? (
							<Alert severity='warning'>Не удалось получить блюда Goden. Попробуйте позже.</Alert>
						) : (dishes.data?.length ?? 0) === 0 ? (
							<Typography variant='body2' color='text.secondary'>
								На точке Goden нет блюд
							</Typography>
						) : (
							<Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
								{dishes.data!.map((dish) => (
									<Box key={dish.id} sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
										<Typography sx={{ flex: 1, minWidth: 0 }} noWrap>
											{dish.name}
										</Typography>
										<TextField
											select
											size='small'
											label='Товар'
											value={dish.item ? String(dish.item.id) : NOT_LINKED}
											disabled={linkDish.isPending}
											onChange={(e) => void changeItem(dish, e.target.value)}
											sx={{ width: 260 }}
										>
											<MenuItem value={NOT_LINKED}>Не связано</MenuItem>
											{items.map((item) => (
												<MenuItem
													key={item.id}
													value={String(item.id)}
													disabled={item.goden_dish_id !== null && item.goden_dish_id !== dish.id}
												>
													{item.name}
												</MenuItem>
											))}
										</TextField>
										<Button
											size='small'
											disabled={dish.item !== null}
											onClick={() => {
												setCreating(dish);
												setPrice('');
											}}
											sx={{ textTransform: 'none', flexShrink: 0 }}
										>
											Создать товар
										</Button>
									</Box>
								))}
							</Box>
						)}
					</>
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
