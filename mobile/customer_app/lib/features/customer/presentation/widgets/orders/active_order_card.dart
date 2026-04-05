import 'package:flutter/material.dart';

import '../../../domain/order_model.dart';
import 'active_order_map.dart';
import 'order_status_helpers.dart';

/// Компактная карточка активного заказа на экране списка.
/// При нажатии вызывает [onTap] - родитель открывает детальный экран.
class ActiveOrderCard extends StatelessWidget {
  final ActiveOrderModel order;
  final VoidCallback onTap;

  const ActiveOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = orderStatusColor(order.status, colorScheme);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Карта
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  ActiveOrderMap(order: order),
                  // Градиент снизу чтобы текст читался
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Бейдж «В пути»
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _StatusBadge(
                      status: order.status,
                      color: statusColor,
                    ),
                  ),
                  // Иконка раскрытия
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.open_in_full_rounded,
                        size: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Инфо
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.restaurantName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            order.estimatedTime,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    orderStatusLabel(order.status),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OrderProgressBar(status: order.status),
                  if (order.courier != null) ...[
                    const SizedBox(height: 14),
                    _CourierRow(courier: order.courier!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            orderStatusShort(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderProgressBar extends StatelessWidget {
  final OrderStatus status;

  const _OrderProgressBar({required this.status});

  static const _steps = ['Готовится', 'Собран', 'В пути', 'Рядом'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final step = orderProgressStep(status);

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final lineIndex = i ~/ 2;
          final filled = step > lineIndex;
          return Expanded(
            child: Container(
              height: 3,
              color: filled
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          );
        }
        final dotIndex = i ~/ 2;
        final filled = step > dotIndex;
        final active = step == dotIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: active ? 12 : 10,
          height: active ? 12 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled || active
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
        );
      }),
    );
  }
}

class _CourierRow extends StatelessWidget {
  final CourierModel courier;

  const _CourierRow({required this.courier});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(courier.avatarUrl),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                courier.name,
                style: textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Icon(Icons.star_rounded,
                      size: 11, color: const Color(0xFFF59E0B)),
                  const SizedBox(width: 2),
                  Text(
                    courier.rating.toStringAsFixed(1),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.phone_rounded,
              color: colorScheme.primary, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
