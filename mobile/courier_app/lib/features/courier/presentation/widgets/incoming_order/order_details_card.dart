import 'package:flutter/material.dart';

import '../../../data/courier_mock_data.dart';

class OrderDetailsCard extends StatelessWidget {
  final IncomingOrder order;

  const OrderDetailsCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        children: [
          // Route: restaurant → customer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _RouteRow(
                  icon: Icons.store_rounded,
                  iconColor: colorScheme.primary,
                  label: 'Забрать',
                  address: order.restaurantName,
                  subtitle: order.restaurantAddress,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: Column(
                    children: List.generate(
                      3,
                      (i) => Container(
                        width: 2,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
                _RouteRow(
                  icon: Icons.location_on_rounded,
                  iconColor: colorScheme.error,
                  label: 'Доставить',
                  address: order.customerAddress,
                  subtitle: null,
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant),

          // Metrics row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _MetricChip(
                  icon: Icons.route_rounded,
                  label: '${order.distanceKm} км',
                  color: const Color(0xFF0EA5E9),
                ),
                const SizedBox(width: 10),
                _MetricChip(
                  icon: Icons.access_time_rounded,
                  label: '~${order.estimatedMinutes} мин',
                  color: const Color(0xFFF97316),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${order.payment.toInt()} ₽',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant),

          // Items list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Состав заказа',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(right: 8, top: 1),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.name,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '× ${item.quantity}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;
  final String? subtitle;

  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              Text(
                address,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
