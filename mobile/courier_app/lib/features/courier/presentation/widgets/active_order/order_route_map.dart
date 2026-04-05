import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../../domain/active_order_model.dart';
import '../../providers/location_provider.dart';
import '../../providers/route_provider.dart';

class OrderRouteMap extends ConsumerStatefulWidget {
  final ActiveOrderModel order;
  final ActiveOrderStage stage;

  const OrderRouteMap({
    super.key,
    required this.order,
    required this.stage,
  });

  @override
  ConsumerState<OrderRouteMap> createState() => _OrderRouteMapState();
}

class _OrderRouteMapState extends ConsumerState<OrderRouteMap> {
  YandexMapController? _controller;

  // Map objects managed declaratively
  PlacemarkMapObject? _courierMarker;
  PlacemarkMapObject? _destinationMarker;
  PolylineMapObject? _routePolyline;

  // Cached bitmaps
  Uint8List? _courierBitmap;
  final _pinBitmaps = <Color, Uint8List>{};

  ProviderSubscription<Point?>? _locationSub;
  ProviderSubscription<RouteState>? _routeSub;

  @override
  void initState() {
    super.initState();
    _locationSub = ref.listenManual(locationProvider, (_, pos) {
      if (pos != null) _updateCourierMarker(pos);
    });
    _routeSub = ref.listenManual(routeProvider, (_, rs) {
      _updatePolyline(rs.points);
    });
  }

  @override
  void didUpdateWidget(OrderRouteMap old) {
    super.didUpdateWidget(old);
    if (old.stage != widget.stage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchRoute(widget.stage);
      });
    }
  }

  @override
  void dispose() {
    _locationSub?.close();
    _routeSub?.close();
    _controller?.dispose();
    super.dispose();
  }

  void _onMapCreated(YandexMapController controller) {
    _controller = controller;

    final initialPos = ref.read(locationProvider) ?? widget.order.restaurantPoint;
    _moveCamera(initialPos, zoom: 14);

    _drawDestinationMarker(widget.stage);

    final courierPos = ref.read(locationProvider);
    if (courierPos != null) {
      _updateCourierMarker(courierPos);
      _fetchRoute(widget.stage);
    } else {
      ProviderSubscription<Point?>? sub;
      sub = ref.listenManual(locationProvider, (_, pos) {
        if (pos != null && mounted) {
          _updateCourierMarker(pos);
          _fetchRoute(widget.stage);
          sub?.close();
        }
      });
    }
  }

  void _fetchRoute(ActiveOrderStage stage) {
    if (stage == ActiveOrderStage.delivered ||
        stage == ActiveOrderStage.awaitingConfirmation) { return; }
    final courierPos = ref.read(locationProvider);
    if (courierPos == null) return;

    final destination = stage == ActiveOrderStage.toRestaurant
        ? widget.order.restaurantPoint
        : widget.order.customerPoint;

    ref.read(routeProvider.notifier).fetch(origin: courierPos, destination: destination);
    _drawDestinationMarker(stage);
    _moveCameraToFit(courierPos, destination);
  }

  Future<void> _drawDestinationMarker(ActiveOrderStage stage) async {
    if (!mounted) return;

    final point = stage == ActiveOrderStage.toRestaurant
        ? widget.order.restaurantPoint
        : widget.order.customerPoint;

    final color = stage == ActiveOrderStage.toRestaurant
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE53935);

    _pinBitmaps[color] ??= await _renderPinBitmap(color);
    if (!mounted) return;

    final marker = PlacemarkMapObject(
      mapId: const MapObjectId('destination'),
      point: point,
      opacity: 1.0,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromBytes(_pinBitmaps[color]!),
          anchor: const Offset(0.5, 1.0),
        ),
      ),
    );

    setState(() => _destinationMarker = marker);
  }

  Future<void> _updateCourierMarker(Point pos) async {
    if (!mounted) return;

    _courierBitmap ??= await _renderCourierBitmap();
    if (!mounted) return;

    final marker = PlacemarkMapObject(
      mapId: const MapObjectId('courier'),
      point: pos,
      opacity: 1.0,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromBytes(_courierBitmap!),
          anchor: const Offset(0.5, 0.5),
        ),
      ),
    );

    setState(() => _courierMarker = marker);
  }

  void _updatePolyline(List<Point> points) {
    if (!mounted) return;

    if (points.isEmpty) {
      setState(() => _routePolyline = null);
      return;
    }

    setState(() {
      _routePolyline = PolylineMapObject(
        mapId: const MapObjectId('route'),
        polyline: Polyline(points: points),
        strokeColor: const Color(0xFF1565C0),
        strokeWidth: 5.0,
        outlineColor: Colors.white,
        outlineWidth: 1.5,
      );
    });
  }

  Future<Uint8List> _renderPinBitmap(Color color) async {
    const w = 40.0, h = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final path = Path()
      ..moveTo(w / 2, h)
      ..quadraticBezierTo(0, h * 0.6, 0, w / 2)
      ..arcToPoint(Offset(w, w / 2),
          radius: Radius.circular(w / 2), clockwise: true)
      ..quadraticBezierTo(w, h * 0.6, w / 2, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
        Offset(w / 2, w / 2), w / 2 - 8, Paint()..color = Colors.white);
    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<Uint8List> _renderCourierBitmap() async {
    const size = 40.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4,
        Paint()..color = const Color(0xFF1565C0));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  void _moveCamera(Point point, {double zoom = 14}) {
    _controller?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: zoom),
      ),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.4),
    );
  }

  void _moveCameraToFit(Point a, Point b) {
    _controller?.moveCamera(
      CameraUpdate.newGeometry(Geometry.fromBoundingBox(BoundingBox(
        southWest: Point(
          latitude: math.min(a.latitude, b.latitude),
          longitude: math.min(a.longitude, b.longitude),
        ),
        northEast: Point(
          latitude: math.max(a.latitude, b.latitude),
          longitude: math.max(a.longitude, b.longitude),
        ),
      ))),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.5),
    );
  }

  List<MapObject> get _mapObjects => [
    ?_routePolyline,
    ?_destinationMarker,
    ?_courierMarker,
  ];

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(routeProvider).isLoading;
    return Stack(
      children: [
        YandexMap(
          onMapCreated: _onMapCreated,
          mapObjects: _mapObjects,
        ),
        if (isLoading)
          const Positioned(
            top: 80, left: 0, right: 0,
            child: Center(child: _LoadingPill()),
          ),
      ],
    );
  }
}

// ─── Loading pill ─────────────────────────────────────────────────────────────

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          const SizedBox(width: 8),
          Text('Строю маршрут...', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
