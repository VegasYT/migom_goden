import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../../domain/delivery_zone_model.dart';

class DeliveryZoneMap extends StatefulWidget {
  final DeliveryZoneModel zone;
  final ValueChanged<Point> onCenterChanged;

  const DeliveryZoneMap({
    super.key,
    required this.zone,
    required this.onCenterChanged,
  });

  @override
  State<DeliveryZoneMap> createState() => _DeliveryZoneMapState();
}

class _DeliveryZoneMapState extends State<DeliveryZoneMap> {
  YandexMapController? _controller;
  Uint8List? _pinBytes;
  bool _ready = false;

  bool _dragging = false;
  Point? _dragCenter;

  // Local-space center of the zone (relative to this widget), refreshed on every camera move
  Offset? _centerLocal;
  double _radiusPx = 80;


  @override
  void initState() {
    super.initState();
    _renderPin().then((b) {
      if (mounted) setState(() => _pinBytes = b);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DeliveryZoneMap old) {
    super.didUpdateWidget(old);
    if (!_dragging &&
        (old.zone.radiusKm != widget.zone.radiusKm ||
            old.zone.center != widget.zone.center)) {
      _fitCamera(widget.zone);
    }
    _updateCenterScreen();
  }

  // ── Pin bitmap ──────────────────────────────────────────────────────────────

  Future<Uint8List> _renderPin() async {
    const w = 36.0, h = 50.0;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    const color = Color(0xFF1565C0);
    final path = Path()
      ..moveTo(w / 2, h)
      ..quadraticBezierTo(0, h * 0.6, 0, w / 2)
      ..arcToPoint(Offset(w, w / 2),
          radius: Radius.circular(w / 2), clockwise: true)
      ..quadraticBezierTo(w, h * 0.6, w / 2, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
        Offset(w / 2, w / 2), w / 2 - 7, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(w / 2, w / 2), w / 2 - 14, Paint()..color = color);
    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  // ── Camera ──────────────────────────────────────────────────────────────────

  void _onMapCreated(YandexMapController c) {
    _controller = c;
    _fitCamera(widget.zone);
    setState(() => _ready = true);
    // first refresh after map is ready
    Future.delayed(const Duration(milliseconds: 600), _updateCenterScreen);
  }

  void _fitCamera(DeliveryZoneModel zone) {
    final delta = zone.radiusKm / 111.0 * 1.6;
    final c = zone.center;
    _controller?.moveCamera(
      CameraUpdate.newGeometry(Geometry.fromBoundingBox(BoundingBox(
        southWest: Point(
            latitude: c.latitude - delta, longitude: c.longitude - delta),
        northEast: Point(
            latitude: c.latitude + delta, longitude: c.longitude + delta),
      ))),
      animation:
          const MapAnimation(type: MapAnimationType.smooth, duration: 0.4),
    );
  }

  void _onCameraPositionChanged(
      CameraPosition pos, CameraUpdateReason reason, bool finished) {
    if (finished) _updateCenterScreen();
  }

  void _updateCenterScreen() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final center = _dragCenter ?? widget.zone.center;

    ctrl.getScreenPoint(center).then((sp) async {
      if (!mounted || sp == null) return;

      final dpr = MediaQuery.of(context).devicePixelRatio;

      final northPoint = Point(
        latitude: center.latitude + widget.zone.radiusKm / 111.0,
        longitude: center.longitude,
      );
      final northSp = await ctrl.getScreenPoint(northPoint);
      if (!mounted) return;

      final radiusPx = northSp != null
          ? ((northSp.y - sp.y).abs() / dpr).clamp(40.0, 2000.0)
          : 80.0;

      setState(() {
        _centerLocal = Offset(sp.x / dpr, sp.y / dpr);
        _radiusPx = radiusPx;
      });
    });
  }

  // ── Pointer / drag ──────────────────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    final cl = _centerLocal;
    if (cl == null) return;
    final dist = (event.localPosition - cl).distance;
    if (dist <= _radiusPx * 0.5) {
      setState(() => _dragging = true);
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_dragging || _controller == null) return;

    final dpr = MediaQuery.of(context).devicePixelRatio;
    _controller!
        .getPoint(ScreenPoint(
            x: event.localPosition.dx * dpr,
            y: event.localPosition.dy * dpr))
        .then((point) {
      if (point != null && mounted && _dragging) {
        setState(() {
          _dragCenter = point;
          _centerLocal = event.localPosition;
        });
      }
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_dragging) return;
    final committed = _dragCenter;
    setState(() {
      _dragging = false;
      _dragCenter = null;
    });
    if (committed != null) {
      widget.onCenterChanged(committed);
    }
    _updateCenterScreen();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!_dragging) return;
    final committed = _dragCenter;
    setState(() {
      _dragging = false;
      _dragCenter = null;
    });
    if (committed != null) {
      widget.onCenterChanged(committed);
    }
    _updateCenterScreen();
  }

  // ── Map objects ─────────────────────────────────────────────────────────────

  List<MapObject> _mapObjects() {
    final pin = _pinBytes;
    if (pin == null) return [];
    final center = _dragCenter ?? widget.zone.center;
    return [
      CircleMapObject(
        mapId: const MapObjectId('zone_fill'),
        circle: Circle(center: center, radius: widget.zone.radiusKm * 1000),
        strokeColor: const Color(0xFF1565C0),
        strokeWidth: _dragging ? 3.0 : 2.5,
        fillColor:
            _dragging ? const Color(0x301565C0) : const Color(0x201565C0),
      ),
      PlacemarkMapObject(
        mapId: const MapObjectId('zone_center'),
        point: center,
        opacity: 1.0,
        icon: PlacemarkIcon.single(PlacemarkIconStyle(
          image: BitmapDescriptor.fromBytes(pin),
          anchor: const Offset(0.5, 1.0),
        )),
      ),
    ];
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          behavior: HitTestBehavior.translucent,
          child: YandexMap(
            scrollGesturesEnabled: !_dragging,
            zoomGesturesEnabled: !_dragging,
            rotateGesturesEnabled: !_dragging,
            tiltGesturesEnabled: !_dragging,
            mapObjects: _ready ? _mapObjects() : [],
            onMapCreated: _onMapCreated,
            onCameraPositionChanged: _onCameraPositionChanged,
            // Give our Listener priority in gesture arena
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer()),
            },
          ),
        ),

        if (!_dragging)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest.withValues(alpha: 0.93),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 8)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drag_indicator_rounded,
                        size: 15, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Зажмите в центре зоны и тяните',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        if (_dragging)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_with_rounded,
                        size: 15, color: cs.onPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Перемещение зоны...',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
