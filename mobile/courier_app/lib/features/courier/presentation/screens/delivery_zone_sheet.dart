import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../domain/delivery_zone_model.dart';
import '../providers/delivery_zone_provider.dart';
import '../widgets/delivery_zone/delivery_zone_map.dart';

class DeliveryZoneSheet extends ConsumerStatefulWidget {
  const DeliveryZoneSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const DeliveryZoneSheet(),
    );
  }

  @override
  ConsumerState<DeliveryZoneSheet> createState() => _DeliveryZoneSheetState();
}

class _DeliveryZoneSheetState extends ConsumerState<DeliveryZoneSheet> {
  late DeliveryZoneModel _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(deliveryZoneProvider);
  }

  void _onCenterChanged(Point center) {
    setState(() => _draft = _draft.copyWith(center: center));
  }

  void _onRadiusChanged(double km) {
    setState(() => _draft = _draft.copyWith(radiusKm: km));
  }

  void _save() {
    ref
        .read(deliveryZoneProvider.notifier)
        .update(center: _draft.center, radiusKm: _draft.radiusKm);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenH = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenH * 0.88,
      child: Column(
        children: [
          // ── Handle & header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Зона доставки',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Заказы будут приходить только из ресторанов в этой зоне',
                  style:
                      tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Map ──────────────────────────────────────────────────────────
          Expanded(
            child: DeliveryZoneMap(
              zone: _draft,
              onCenterChanged: _onCenterChanged,
            ),
          ),

          // ── Controls ─────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RadiusSlider(
                  radiusKm: _draft.radiusKm,
                  onChanged: _onRadiusChanged,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Сохранить зону',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Radius slider ─────────────────────────────────────────────────────────────

class _RadiusSlider extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;

  const _RadiusSlider({required this.radiusKm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.radar_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text('Радиус зоны',
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${radiusKm.toStringAsFixed(1)} км',
              style: tt.bodyMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: radiusKm,
            min: 0.5,
            max: 15.0,
            divisions: 29,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0.5 км',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            Text('15 км',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}
