import { useMemo } from 'react';
import { Box, Typography, Chip } from '@mui/material';
import { YMaps, Map, Placemark, ZoomControl } from '@pbe/react-yandex-maps';
import type { Outlet } from '../types';

const YMAPS_KEY = import.meta.env.VITE_YANDEX_MAPS_API_KEY as
	| string
	| undefined;
const DEFAULT_CENTER: [number, number] = [55.7558, 37.6176]; // Москва [lat, lng]

interface Props {
	outlets: Outlet[];
}

export function OutletsMap({ outlets }: Props) {
	const validOutlets = outlets.filter((o) => {
		const lat = parseFloat(o.latitude);
		const lng = parseFloat(o.longitude);
		return !isNaN(lat) && !isNaN(lng) && lat !== 0 && lng !== 0;
	});

	// Ключ для пересоздания карты при изменении точек
	const mapKey = validOutlets
		.map((o) => `${o.id}:${o.latitude}:${o.longitude}:${o.is_active}`)
		.join('|');

	// Начальное состояние карты: один центр или bounds по всем точкам
	const mapDefaultState = useMemo(() => {
		if (validOutlets.length === 0) {
			return { center: DEFAULT_CENTER, zoom: 12 };
		}
		const lats = validOutlets.map((o) => parseFloat(o.latitude));
		const lngs = validOutlets.map((o) => parseFloat(o.longitude));

		if (validOutlets.length === 1) {
			return { center: [lats[0], lngs[0]] as [number, number], zoom: 15 };
		}

		const pad = 0.005;
		return {
			bounds: [
				[Math.min(...lats) - pad, Math.min(...lngs) - pad],
				[Math.max(...lats) + pad, Math.max(...lngs) + pad],
			] as [[number, number], [number, number]],
		};
	}, [mapKey]); // eslint-disable-line react-hooks/exhaustive-deps

	if (validOutlets.length === 0) return null;

	return (
		<Box
			sx={{
				bgcolor: 'background.paper',
				border: '1px solid',
				borderColor: 'divider',
				borderRadius: 3,
				overflow: 'hidden',
				mb: 3,
			}}
		>
			<Box
				sx={{
					display: 'flex',
					alignItems: 'center',
					gap: 1,
					px: 2.5,
					py: 1.5,
					borderBottom: '1px solid',
					borderColor: 'divider',
				}}
			>
				<Typography variant='subtitle2' fontWeight={600} color='text.primary'>
					Точки на карте
				</Typography>
				<Chip
					label={validOutlets.length}
					size='small'
					sx={{
						height: 18,
						fontSize: 10,
						bgcolor: 'action.selected',
						color: 'text.secondary',
					}}
				/>
			</Box>

			<YMaps
				version='2.1'
				query={{ apikey: YMAPS_KEY, lang: 'ru_RU', load: 'package.full' }}
			>
				<Map
					key={mapKey}
					defaultState={mapDefaultState}
					style={{ width: '100%', height: 320 }}
				>
					{validOutlets.map((outlet) => (
						<Placemark
							key={outlet.id}
							geometry={[
								parseFloat(outlet.latitude),
								parseFloat(outlet.longitude),
							]}
							properties={{
								hintContent: outlet.name,
								balloonContent: `<b>${outlet.name}</b><br>${outlet.address}`,
							}}
							options={{
								preset: outlet.is_active
									? 'islands#greenCircleDotIcon'
									: 'islands#grayCircleDotIcon',
							}}
						/>
					))}
					<ZoomControl options={{ position: { right: 10, top: 108 } }} />
				</Map>
			</YMaps>
		</Box>
	);
}
