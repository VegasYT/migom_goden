import { useRef } from 'react';
import { Box } from '@mui/material';
import { YMaps, Map, Placemark, ZoomControl } from '@pbe/react-yandex-maps';

const YMAPS_KEY = import.meta.env.VITE_YANDEX_MAPS_API_KEY as
	| string
	| undefined;

interface Props {
	outletCoords: [number, number];
	deliveryCoords: [number, number];
	outletName?: string;
}

export function OrderRouteMap({
	outletCoords,
	deliveryCoords,
	outletName,
}: Props) {
	const mapRef = useRef<ymaps.Map | null>(null);

	const pad = 0.003;
	const lats = [outletCoords[0], deliveryCoords[0]];
	const lngs = [outletCoords[1], deliveryCoords[1]];

	const bounds: [[number, number], [number, number]] = [
		[Math.min(...lats) - pad, Math.min(...lngs) - pad],
		[Math.max(...lats) + pad, Math.max(...lngs) + pad],
	];

	const handleMapLoad = (ymapsApi: typeof globalThis.ymaps) => {
		const map = mapRef.current;
		if (!map) return;

		const multiRoute = new ymapsApi.multiRouter.MultiRoute(
			{
				referencePoints: [outletCoords, deliveryCoords],
				params: { routingMode: 'auto' },
			},
			{
				routeActiveStrokeWidth: 4,
				routeActiveStrokeColor: '#4ADE80',
				routeStrokeWidth: 2,
				routeStrokeColor: '#8896A7',
				boundsAutoApply: true,
				// Скрываем стандартные точки маршрута - используем свои Placemark
				wayPointVisible: false,
				pinVisible: false,
			}
		);
		map.geoObjects.add(multiRoute as unknown as ymaps.GeoObject);
	};

	return (
		<Box
			sx={{
				borderRadius: 2,
				overflow: 'hidden',
				border: '1px solid',
				borderColor: 'divider',
				mt: 1.5,
			}}
		>
			<YMaps
				version='2.1'
				query={{
					apikey: YMAPS_KEY,
					lang: 'ru_RU',
					load: 'package.full',
				}}
			>
				<Map
					defaultState={{ bounds }}
					style={{ width: '100%', height: 220 }}
					instanceRef={(ref) => {
						mapRef.current = ref;
					}}
					onLoad={handleMapLoad}
					modules={['multiRouter.MultiRoute']}
				>
					<Placemark
						geometry={outletCoords}
						properties={{ hintContent: outletName ?? 'Точка продаж' }}
						options={{ preset: 'islands#greenCircleDotIcon' }}
					/>
					<Placemark
						geometry={deliveryCoords}
						properties={{ hintContent: 'Адрес доставки' }}
						options={{ preset: 'islands#redCircleDotIcon' }}
					/>
					<ZoomControl options={{ position: { right: 10, top: 10 } }} />
				</Map>
			</YMaps>
		</Box>
	);
}
