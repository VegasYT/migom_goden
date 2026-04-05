import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/shift_provider.dart';

class ShiftStatsRow extends ConsumerWidget {
  const ShiftStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final items = [
      _StatItem(
        icon: Icons.local_shipping_rounded,
        value: shift.ordersCompleted.toString(),
        label: 'Заказов',
        color: colorScheme.primary,
      ),
      _StatItem(
        icon: Icons.attach_money_rounded,
        value: shift.earned == 0 ? '-' : '${shift.earned.toInt()} ₽',
        label: 'Заработано',
        color: const Color(0xFF10B981),
      ),
      _StatItem(
        icon: Icons.route_rounded,
        value: shift.distanceKm == 0 ? '-' : '${shift.distanceKm.toStringAsFixed(1)} км',
        label: 'Расстояние',
        color: const Color(0xFF0EA5E9),
      ),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(child: _StatCard(item: e.value)),
              if (!isLast)
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, size: 18, color: item.color),
        ),
        const SizedBox(height: 6),
        Text(
          item.value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          item.label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
