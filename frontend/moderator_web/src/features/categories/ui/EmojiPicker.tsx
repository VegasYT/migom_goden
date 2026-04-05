import { useState } from 'react';
import {
	Box,
	Popover,
	Typography,
	InputAdornment,
	IconButton,
	TextField,
	Tabs,
	Tab,
} from '@mui/material';

const EMOJI_GROUPS = [
	{
		label: 'Еда',
		emojis: [
			'🍕',
			'🍔',
			'🍟',
			'🌭',
			'🌮',
			'🌯',
			'🥙',
			'🧆',
			'🥗',
			'🥘',
			'🍝',
			'🍜',
			'🍲',
			'🍛',
			'🍣',
			'🍱',
			'🥟',
			'🍤',
			'🍚',
			'🍘',
			'🥞',
			'🧇',
			'🥐',
			'🍞',
			'🥖',
			'🥨',
			'🧀',
			'🥚',
			'🍳',
			'🥓',
			'🥩',
			'🍗',
			'🍖',
			'🥪',
			'🥙',
			'🧁',
			'🍰',
			'🎂',
			'🍮',
			'🍩',
			'🍪',
			'🍫',
			'🍬',
			'🍭',
			'🍡',
			'🍧',
			'🍦',
			'🥧',
			'🥮',
			'🍿',
		],
	},
	{
		label: 'Напитки',
		emojis: [
			'☕',
			'🍵',
			'🧋',
			'🥤',
			'🍶',
			'🍺',
			'🍻',
			'🥂',
			'🍷',
			'🍸',
			'🍹',
			'🧃',
			'🥛',
			'🍼',
			'🫖',
			'🧊',
		],
	},
	{
		label: 'Фрукты',
		emojis: [
			'🍎',
			'🍐',
			'🍊',
			'🍋',
			'🍌',
			'🍉',
			'🍇',
			'🍓',
			'🫐',
			'🍒',
			'🍑',
			'🥭',
			'🍍',
			'🥝',
			'🥥',
			'🍈',
			'🍅',
			'🥑',
			'🫒',
		],
	},
	{
		label: 'Овощи',
		emojis: [
			'🥦',
			'🥬',
			'🥒',
			'🌶️',
			'🫑',
			'🌽',
			'🥕',
			'🧅',
			'🧄',
			'🥔',
			'🍆',
			'🫘',
			'🌰',
			'🥜',
			'🍄',
		],
	},
	{
		label: 'Разное',
		emojis: [
			'🛒',
			'📦',
			'🎁',
			'⭐',
			'🔥',
			'❤️',
			'💚',
			'🏷️',
			'🍽️',
			'🥡',
			'🧂',
			'🫙',
			'🍯',
			'♨️',
			'🥢',
			'🔪',
		],
	},
];

interface Props {
	value: string;
	onChange: (emoji: string) => void;
	onBlur?: () => void;
	error?: boolean;
	helperText?: string;
}

export function EmojiPicker({
	value,
	onChange,
	onBlur,
	error,
	helperText,
}: Props) {
	const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
	const [tab, setTab] = useState(0);

	const handleOpen = (e: React.MouseEvent<HTMLElement>) => {
		setAnchorEl(e.currentTarget);
	};

	const handleClose = () => {
		setAnchorEl(null);
		onBlur?.();
	};

	const handleSelect = (emoji: string) => {
		onChange(emoji);
		handleClose();
	};

	return (
		<>
			<TextField
				label='Эмодзи'
				value={value}
				onChange={(e) => onChange(e.target.value)}
				onBlur={onBlur}
				error={error}
				helperText={helperText}
				fullWidth
				slotProps={{
					input: {
						readOnly: true,
						endAdornment: (
							<InputAdornment position='end'>
								<IconButton size='small' onClick={handleOpen}>
									<Typography variant='body2'>{value ? '✏️' : '😀'}</Typography>
								</IconButton>
							</InputAdornment>
						),
						sx: { cursor: 'pointer' },
					},
				}}
				onClick={handleOpen}
			/>

			<Popover
				open={Boolean(anchorEl)}
				anchorEl={anchorEl}
				onClose={handleClose}
				anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
				transformOrigin={{ vertical: 'top', horizontal: 'left' }}
				slotProps={{
					paper: {
						sx: { width: 320, maxHeight: 380 },
					},
				}}
			>
				<Tabs
					value={tab}
					onChange={(_, v: number) => setTab(v)}
					variant='scrollable'
					scrollButtons='auto'
					sx={{ minHeight: 36, borderBottom: 1, borderColor: 'divider' }}
				>
					{EMOJI_GROUPS.map((group) => (
						<Tab
							key={group.label}
							label={group.label}
							sx={{ minHeight: 36, py: 0.5, fontSize: 12 }}
						/>
					))}
				</Tabs>
				<Box
					sx={{
						display: 'flex',
						flexWrap: 'wrap',
						gap: 0.25,
						p: 1,
					}}
				>
					{EMOJI_GROUPS[tab].emojis.map((emoji) => (
						<Box
							key={emoji}
							onClick={() => handleSelect(emoji)}
							sx={{
								width: 36,
								height: 36,
								display: 'flex',
								alignItems: 'center',
								justifyContent: 'center',
								borderRadius: 1,
								cursor: 'pointer',
								fontSize: 20,
								'&:hover': { bgcolor: 'action.hover' },
								...(emoji === value && {
									bgcolor: 'action.selected',
									outline: '2px solid',
									outlineColor: 'primary.main',
								}),
							}}
						>
							{emoji}
						</Box>
					))}
				</Box>
			</Popover>
		</>
	);
}
