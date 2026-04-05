import { useState } from 'react';
import {
	Dialog,
	DialogTitle,
	DialogContent,
	DialogActions,
	Button,
	Box,
	Typography,
	CircularProgress,
} from '@mui/material';
import MyLocationIcon from '@mui/icons-material/MyLocation';
import {
	YMaps,
	Map,
	Placemark,
	ZoomControl,
	useYMaps,
} from '@pbe/react-yandex-maps';

const YMAPS_KEY = import.meta.env.VITE_YANDEX_MAPS_API_KEY as
	| string
	| undefined;
const DEFAULT_CENTER: [number, number] = [55.7558, 37.6176]; // Москва [lat, lng]
const DEFAULT_ZOOM = 12;

interface Props {
	open: boolean;
	onClose: () => void;
	initialLat?: string;
	initialLng?: string;
	onConfirm: (lat: string, lng: string, address?: string) => void;
}

interface MapContentProps {
	mapDefaultState: { center: [number, number]; zoom: number };
	coords: [number, number] | null;
	onCoordsChange: (c: [number, number]) => void;
	onAddressResolved: (address: string | null) => void;
	onAddressLoading: (loading: boolean) => void;
}

// Вынесен отдельным компонентом, чтобы использовать useYMaps внутри <YMaps> провайдера
function MapContent({
	mapDefaultState,
	coords,
	onCoordsChange,
	onAddressResolved,
	onAddressLoading,
}: MapContentProps) {
	const yMaps = useYMaps(['geocode']);

	const handleClick = (e: ymaps.IEvent) => {
		const c = e.get('coords') as [number, number]; // [lat, lng]
		onCoordsChange(c);
		onAddressLoading(true);
		onAddressResolved(null);
		void yMaps
			?.geocode(c, { results: 1 })
			.then((res) => {
				// eslint-disable-next-line @typescript-eslint/no-explicit-any
				const obj = res.geoObjects.get(0) as any;
				onAddressResolved(obj ? (obj.getAddressLine() as string) : null);
				onAddressLoading(false);
			})
			.catch(() => {
				onAddressResolved(null);
				onAddressLoading(false);
			});
	};

	return (
		<Map
			defaultState={mapDefaultState}
			style={{ width: '100%', height: 450 }}
			onClick={handleClick}
		>
			{coords && (
				<Placemark
					geometry={coords}
					options={{
						iconColor: '#4ADE80',
						preset: 'islands#circleIcon',
					}}
				/>
			)}
			<ZoomControl options={{ position: { right: 10, top: 108 } }} />
		</Map>
	);
}

function MapPickerContent({
	initialLat,
	initialLng,
	onConfirm,
	onClose,
}: Omit<Props, 'open'>) {
	const parsedLat = initialLat ? parseFloat(initialLat) : NaN;
	const parsedLng = initialLng ? parseFloat(initialLng) : NaN;
	const hasInitial = !isNaN(parsedLat) && !isNaN(parsedLng);

	const [coords, setCoords] = useState<[number, number] | null>(
		hasInitial ? [parsedLat, parsedLng] : null
	);
	const [resolvedAddress, setResolvedAddress] = useState<string | null>(null);
	const [addressLoading, setAddressLoading] = useState(false);

	const mapDefaultState = {
		center: hasInitial
			? ([parsedLat, parsedLng] as [number, number])
			: DEFAULT_CENTER,
		zoom: DEFAULT_ZOOM,
	};

	const handleConfirm = () => {
		if (coords) {
			const [lat, lng] = coords;
			onConfirm(lat.toFixed(6), lng.toFixed(6), resolvedAddress ?? undefined);
		}
		onClose();
	};

	return (
		<>
			<DialogContent sx={{ p: 0 }}>
				<Box sx={{ position: 'relative' }}>
					<YMaps
						query={{ apikey: YMAPS_KEY, lang: 'ru_RU', load: 'package.full' }}
					>
						<MapContent
							mapDefaultState={mapDefaultState}
							coords={coords}
							onCoordsChange={setCoords}
							onAddressResolved={setResolvedAddress}
							onAddressLoading={setAddressLoading}
						/>
					</YMaps>

					{/* Подсказка */}
					<Box
						sx={{
							position: 'absolute',
							bottom: 12,
							left: '50%',
							transform: 'translateX(-50%)',
							bgcolor: 'background.paper',
							px: 2,
							py: 0.75,
							borderRadius: 2,
							boxShadow: 2,
							border: '1px solid',
							borderColor: 'divider',
							pointerEvents: 'none',
							display: 'flex',
							alignItems: 'center',
							gap: 1,
							maxWidth: 'calc(100% - 40px)',
						}}
					>
						{addressLoading && <CircularProgress size={12} />}
						<Typography variant='caption' color='text.secondary' noWrap>
							{addressLoading
								? 'Определяем адрес...'
								: coords
									? (resolvedAddress ??
										`${coords[0].toFixed(5)}, ${coords[1].toFixed(5)}`)
									: 'Нажмите на карту, чтобы выбрать точку'}
						</Typography>
					</Box>
				</Box>
			</DialogContent>

			<DialogActions sx={{ px: 3, pb: 2.5 }}>
				<Button onClick={onClose} color='inherit'>
					Отмена
				</Button>
				<Button
					variant='contained'
					onClick={handleConfirm}
					disabled={!resolvedAddress || !coords}
					startIcon={<MyLocationIcon />}
				>
					Подтвердить
				</Button>
			</DialogActions>
		</>
	);
}

export function MapPickerDialog({
	open,
	onClose,
	initialLat,
	initialLng,
	onConfirm,
}: Props) {
	return (
		<Dialog open={open} onClose={onClose} maxWidth='md' fullWidth>
			<DialogTitle>Выбрать точку на карте</DialogTitle>
			{open && (
				<MapPickerContent
					onClose={onClose}
					initialLat={initialLat}
					initialLng={initialLng}
					onConfirm={onConfirm}
				/>
			)}
		</Dialog>
	);
}
