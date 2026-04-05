import { useState } from 'react';
import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogActions,
	Button,
	TextField,
	List,
	ListItem,
	ListItemText,
	ListItemAvatar,
	Avatar,
	IconButton,
	Box,
	Typography,
	CircularProgress,
	Tooltip,
} from '@mui/material';
import PersonRemoveOutlinedIcon from '@mui/icons-material/PersonRemoveOutlined';
import PersonAddAlt1OutlinedIcon from '@mui/icons-material/PersonAddAlt1Outlined';
import { useOutletManagers } from '../api/useOutletManagers';
import { useAddManager } from '../api/useAddManager';
import { useRemoveManager } from '../api/useRemoveManager';
import type { Outlet } from '../types';

interface Props {
	open: boolean;
	onClose: () => void;
	outlet: Outlet;
}

export function OutletManagersDialog({ open, onClose, outlet }: Props) {
	const { data: managers, isLoading } = useOutletManagers(open ? outlet.id : null);
	const addManager = useAddManager();
	const removeManager = useRemoveManager();
	const [email, setEmail] = useState('');

	const handleAdd = () => {
		const trimmed = email.trim();
		if (!trimmed) return;
		addManager.mutate(
			{ outletId: outlet.id, dto: { email: trimmed } },
			{ onSuccess: () => setEmail('') },
		);
	};

	return (
		<Dialog open={open} onClose={onClose} maxWidth='sm' fullWidth>
			<DialogTitle>Менеджеры - {outlet.name}</DialogTitle>

			<DialogContent dividers sx={{ p: 0 }}>
				{/* Форма добавления */}
				<Box sx={{ px: 2.5, py: 2, display: 'flex', gap: 1 }}>
					<TextField
						size='small'
						label='Email менеджера'
						placeholder='manager@example.com'
						type='email'
						value={email}
						onChange={(e) => setEmail(e.target.value)}
						onKeyDown={(e) => {
							if (e.key === 'Enter') {
								e.preventDefault();
								handleAdd();
							}
						}}
						fullWidth
					/>
					<Button
						variant='contained'
						size='small'
						disabled={!email.trim() || addManager.isPending}
						onClick={handleAdd}
						startIcon={
							addManager.isPending ? (
								<CircularProgress size={14} color='inherit' />
							) : (
								<PersonAddAlt1OutlinedIcon sx={{ fontSize: '16px !important' }} />
							)
						}
						sx={{ flexShrink: 0, textTransform: 'none' }}
					>
						Добавить
					</Button>
				</Box>

				{/* Список */}
				{isLoading ? (
					<Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
						<CircularProgress />
					</Box>
				) : (managers?.length ?? 0) === 0 ? (
					<Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
						<Typography variant='body2' color='text.secondary'>
							Менеджеры не назначены
						</Typography>
					</Box>
				) : (
					<List disablePadding>
						{managers!.map((m) => (
							<ListItem
								key={m.user_id}
								secondaryAction={
									<Tooltip title='Удалить менеджера'>
										<IconButton
											size='small'
											disabled={removeManager.isPending}
											onClick={() =>
												removeManager.mutate({
													outletId: outlet.id,
													userId: m.user_id,
												})
											}
											sx={{ color: 'error.main' }}
										>
											<PersonRemoveOutlinedIcon fontSize='small' />
										</IconButton>
									</Tooltip>
								}
							>
								<ListItemAvatar sx={{ minWidth: 40 }}>
									<Avatar sx={{ width: 32, height: 32, fontSize: 14, bgcolor: 'primary.main' }}>
										{m.user_full_name.charAt(0).toUpperCase()}
									</Avatar>
								</ListItemAvatar>
								<ListItemText
									primary={m.user_full_name}
									secondary={m.user_email}
									primaryTypographyProps={{ variant: 'body2', fontWeight: 500 }}
									secondaryTypographyProps={{ variant: 'caption' }}
								/>
							</ListItem>
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
