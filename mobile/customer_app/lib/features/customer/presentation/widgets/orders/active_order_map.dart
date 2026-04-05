import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/order_model.dart';

class ActiveOrderMap extends StatefulWidget {
  final ActiveOrderModel order;
  final bool expanded;

  /// Высота панели снизу - карта подписывается на изменения напрямую.
  /// null = карта без панели (свёрнутый режим).
  final ValueNotifier<double>? sheetHeightNotifier;

  /// Начальная доля экрана под панель - используется для первого фокуса
  /// до того как notifier сообщит реальное значение.
  final double sheetInitialFraction;

  const ActiveOrderMap({
    super.key,
    required this.order,
    this.expanded = false,
    this.sheetHeightNotifier,
    this.sheetInitialFraction = 0.46,
  });

  @override
  State<ActiveOrderMap> createState() => _ActiveOrderMapState();
}

class _ActiveOrderMapState extends State<ActiveOrderMap>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();

  late final AnimationController _animController;
  Animation<LatLng>? _latLngAnim;
  Animation<double>? _zoomAnim;

  double get _sheetHeight {
    if (widget.sheetHeightNotifier == null) return 0;
    final v = widget.sheetHeightNotifier!.value;
    // Если notifier ещё не обновился - считаем из fraction
    if (v == 0) {
      final screenH = MediaQuery.sizeOf(context).height;
      return widget.sheetInitialFraction * screenH;
    }
    return v;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(_onAnimTick);
    widget.sheetHeightNotifier?.addListener(_onSheetChanged);
  }

  @override
  void didUpdateWidget(ActiveOrderMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sheetHeightNotifier != oldWidget.sheetHeightNotifier) {
      oldWidget.sheetHeightNotifier?.removeListener(_onSheetChanged);
      widget.sheetHeightNotifier?.addListener(_onSheetChanged);
    }
  }

  @override
  void dispose() {
    widget.sheetHeightNotifier?.removeListener(_onSheetChanged);
    _animController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onAnimTick() {
    if (_latLngAnim == null || _zoomAnim == null) return;
    _mapController.move(_latLngAnim!.value, _zoomAnim!.value);
  }

  void _onSheetChanged() {
    _focusAllPoints();
  }

  // ─── Фокус на все точки ───────────────────────────────────────────────────

  void _focusAllPoints({bool animated = true}) {
    if (!widget.expanded) return;
    final points = _allPoints();
    final zoom = _calcZoom(points);

    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    final geoLat = (lats.reduce(math.min) + lats.reduce(math.max)) / 2;
    final geoLng = (lngs.reduce(math.min) + lngs.reduce(math.max)) / 2;

    final screenH = MediaQuery.sizeOf(context).height;
    final topPad = MediaQuery.of(context).padding.top + 80.0;
    final bottomPad = _sheetHeight + 48.0;
    final visibleMidPx = topPad + (screenH - topPad - bottomPad) / 2;
    final shiftPx = screenH / 2 - visibleMidPx;
    final shiftLat = _pxToLat(shiftPx, zoom);
    final targetCenter = LatLng(geoLat - shiftLat, geoLng);

    if (!animated) {
      _mapController.move(targetCenter, zoom);
      return;
    }

    _animController.stop();
    _latLngAnim = LatLngTween(
      begin: _mapController.camera.center,
      end: targetCenter,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic));
    _zoomAnim = Tween<double>(
      begin: _mapController.camera.zoom,
      end: zoom,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic));
    _animController.forward(from: 0);
  }

  // ─── Математика ───────────────────────────────────────────────────────────

  double _calcZoom(List<LatLng> points) {
    if (points.length < 2) return 15.0;

    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    final latDelta = (lats.reduce(math.max) - lats.reduce(math.min)).abs();
    final lngDelta = (lngs.reduce(math.max) - lngs.reduce(math.min)).abs();

    if (latDelta < 0.0005 && lngDelta < 0.0005) return 15.5;

    final screenH = MediaQuery.sizeOf(context).height;
    final topPad = MediaQuery.of(context).padding.top + 80.0;
    final bottomPad = _sheetHeight + 48.0;
    final availableH = (screenH - topPad - bottomPad).clamp(100.0, double.infinity);
    final availableW = (MediaQuery.sizeOf(context).width - 96.0).clamp(100.0, double.infinity);

    const pxPerDegLng0 = 256.0 / 360.0;
    const pxPerDegLat0 = 256.0 / 170.0;

    final zoomLng = math.log(availableW / (lngDelta * pxPerDegLng0)) / math.ln2;
    final zoomLat = math.log(availableH / (latDelta * pxPerDegLat0)) / math.ln2;

    return (math.min(zoomLng, zoomLat) - 0.3).clamp(12.0, 15.5);
  }

  double _pxToLat(double px, double zoom) {
    const pxPerDegLat0 = 256.0 / 170.0;
    return px / (pxPerDegLat0 * math.pow(2, zoom));
  }

  List<LatLng> _allPoints() => [
        widget.order.restaurantLocation,
        widget.order.deliveryLocation,
        if (widget.order.courier != null) widget.order.courier!.location,
      ];

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final courier = widget.order.courier;

    final initialCenter = LatLng(
      (widget.order.restaurantLocation.latitude +
              widget.order.deliveryLocation.latitude) /
          2,
      (widget.order.restaurantLocation.longitude +
              widget.order.deliveryLocation.longitude) /
          2,
    );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 14.0,
        interactionOptions: InteractionOptions(
          flags: widget.expanded ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onMapReady: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _focusAllPoints(animated: false);
          });
        },
        onPositionChanged: (_, __) {},
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.migom.customer_app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: widget.order.restaurantLocation,
              width: 36,
              height: 36,
              child: _MapPin(icon: Icons.storefront_rounded, color: colorScheme.tertiary),
            ),
            Marker(
              point: widget.order.deliveryLocation,
              width: 36,
              height: 36,
              child: _MapPin(icon: Icons.home_rounded, color: colorScheme.primary),
            ),
            if (courier != null)
              Marker(
                point: courier.location,
                width: 44,
                height: 44,
                child: _CourierPin(color: colorScheme.primary),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── LatLng tween ──────────────────────────────────────────────────────────────

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) => LatLng(
        begin!.latitude + (end!.latitude - begin!.latitude) * t,
        begin!.longitude + (end!.longitude - begin!.longitude) * t,
      );
}

// ─── Пины ──────────────────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MapPin({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _CourierPin extends StatelessWidget {
  final Color color;
  const _CourierPin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(Icons.delivery_dining_rounded, color: color, size: 22),
    );
  }
}
