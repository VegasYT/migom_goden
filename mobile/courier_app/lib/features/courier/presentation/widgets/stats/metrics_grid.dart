import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/stats_provider.dart';

class MetricsGrid extends ConsumerWidget {
  const MetricsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(currentPeriodStatsProvider);

    final items = [
      _MetricItem(
        icon: Icons.local_shipping_rounded,
        color: const Color(0xFF10B981),
        value: stats.ordersCompleted.toString(),
        label: 'Заказов\nвыполнено',
      ),
      _MetricItem(
        icon: Icons.access_time_rounded,
        color: const Color(0xFFF97316),
        value: '${stats.avgDeliveryMinutes.toInt()} мин',
        label: 'Среднее время\nдоставки',
      ),
      _MetricItem(
        icon: Icons.receipt_rounded,
        color: const Color(0xFF0EA5E9),
        value: '${stats.avgOrderAmount.toInt()} ₽',
        label: 'Средний\nчек заказа',
      ),
      _MetricItem(
        icon: Icons.route_rounded,
        color: const Color(0xFF8B5CF6),
        value: '${stats.distanceKm} км',
        label: 'Общий\nпробег',
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(item: items[0])),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(item: items[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _MetricCard(item: items[2])),
            const SizedBox(width: 10),
            Expanded(child: _MetricCard(item: items[3])),
          ],
        ),
      ],
    );
  }
}

class _MetricItem {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MetricItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricItem item;
  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(item.icon, size: 17, color: item.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  key: ValueKey(item.value),
                  item.value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                item.label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
