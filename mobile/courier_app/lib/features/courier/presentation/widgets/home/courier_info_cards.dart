import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/courier_profile_provider.dart';
import '../../providers/delivery_zone_provider.dart';
import '../../providers/shift_provider.dart';
import '../../screens/delivery_zone_sheet.dart';
import '../../screens/vehicle_type_sheet.dart';

class CourierInfoCards extends ConsumerWidget {
  const CourierInfoCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftProvider);
    final profile = ref.watch(courierProfileSyncProvider);
    final zone = ref.watch(deliveryZoneProvider);
    final cs = Theme.of(context).colorScheme;

    final zoneSubtitle =
        'Радиус ${zone.radiusKm.toStringAsFixed(1)} км · '
        '${zone.center.latitude.toStringAsFixed(4)}, '
        '${zone.center.longitude.toStringAsFixed(4)}';

    return Column(
      children: [
        _InfoCard(
          icon: Icons.map_outlined,
          iconColor: const Color(0xFF0EA5E9),
          title: 'Зона доставки',
          subtitle: zoneSubtitle,
          trailing: _ChipButton(
            label: 'Изменить',
            onTap: () => DeliveryZoneSheet.show(context),
          ),
        ),
        const SizedBox(height: 10),

        _InfoCard(
          icon: shift.isActive
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          iconColor: shift.isActive
              ? cs.primary
              : cs.onSurfaceVariant,
          title: shift.isActive ? 'Принимаю заказы' : 'Не в сети',
          subtitle: shift.isActive
              ? 'Доступен для новых заказов'
              : 'Начните смену, чтобы получать заказы',
          trailing: null,
        ),
        const SizedBox(height: 10),

        _InfoCard(
          icon: Icons.directions_bike_rounded,
          iconColor: const Color(0xFFF97316),
          title: 'Транспорт',
          subtitle: profile.vehicleType.label,
          trailing: _ChipButton(
            label: 'Изменить',
            onTap: () => VehicleTypeSheet.show(context),
          ),
        ),
      ],
    );
  }
}

// ─── Card ──────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ─── Chip button ───────────────────────────────────────────────────────────────

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}
