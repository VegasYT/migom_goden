import 'package:flutter/material.dart';

import '../../../domain/active_order_model.dart';
import 'delivery_timer.dart';

/// Bottom sheet overlay showing order details, timer, and action button.
class OrderInfoSheet extends StatefulWidget {
  final ActiveOrderState orderState;
  final VoidCallback onPickedUp;
  final VoidCallback onDelivered;

  const OrderInfoSheet({
    super.key,
    required this.orderState,
    required this.onPickedUp,
    required this.onDelivered,
  });

  @override
  State<OrderInfoSheet> createState() => _OrderInfoSheetState();
}

class _OrderInfoSheetState extends State<OrderInfoSheet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final order = widget.orderState.order;
    final stage = widget.orderState.stage;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const _DragHandle(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stage badge + timer row
                Row(
                  children: [
                    _StageBadge(stage: stage),
                    const Spacer(),
                    DeliveryTimer(
                      secondsRemaining: widget.orderState.secondsRemaining,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Route row
                _RouteRow(order: order, stage: stage),

                const SizedBox(height: 12),

                // Expandable items
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: [
                      Text(
                        'Состав заказа',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: _expanded
                      ? _ItemsList(items: order.items)
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // Action button
                if (stage == ActiveOrderStage.toRestaurant)
                  _ActionButton(
                    label: 'Забрал заказ',
                    icon: Icons.check_circle_outline_rounded,
                    onTap: widget.onPickedUp,
                  )
                else if (stage == ActiveOrderStage.toCustomer)
                  _ActionButton(
                    label: 'Доставил заказ',
                    icon: Icons.flag_rounded,
                    onTap: widget.onDelivered,
                  ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // Safe area bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ─── Stage badge ───────────────────────────────────────────────────────────────

class _StageBadge extends StatelessWidget {
  final ActiveOrderStage stage;

  const _StageBadge({required this.stage});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (label, color) = switch (stage) {
      ActiveOrderStage.toRestaurant => ('Еду в ресторан', colorScheme.primary),
      ActiveOrderStage.toCustomer => ('Везу заказ', colorScheme.tertiary),
      ActiveOrderStage.awaitingConfirmation => ('Ожидание', colorScheme.secondary),
      ActiveOrderStage.delivered => ('Доставлено', colorScheme.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
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

// ─── Route row ─────────────────────────────────────────────────────────────────

class _RouteRow extends StatelessWidget {
  final ActiveOrderModel order;
  final ActiveOrderStage stage;

  const _RouteRow({required this.order, required this.stage});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Highlight the active leg
    final restaurantActive = stage == ActiveOrderStage.toRestaurant;
    final customerActive = stage == ActiveOrderStage.toCustomer;

    return Row(
      children: [
        // Restaurant
        Expanded(
          child: _LegCard(
            icon: Icons.store_rounded,
            iconColor: colorScheme.primary,
            title: order.restaurantName,
            subtitle: order.restaurantAddress,
            isActive: restaurantActive,
            isDone: !restaurantActive,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        // Customer
        Expanded(
          child: _LegCard(
            icon: Icons.location_on_rounded,
            iconColor: colorScheme.error,
            title: 'Клиент',
            subtitle: order.customerAddress,
            isActive: customerActive,
            isDone: stage == ActiveOrderStage.delivered,
          ),
        ),
      ],
    );
  }
}

class _LegCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isDone;

  const _LegCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final borderColor = isActive
        ? iconColor.withValues(alpha: 0.5)
        : colorScheme.outlineVariant;
    final bgColor = isActive
        ? iconColor.withValues(alpha: 0.06)
        : colorScheme.surfaceContainerLow;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : icon,
            size: 16,
            color: isDone ? colorScheme.primary : iconColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Items list ────────────────────────────────────────────────────────────────

class _ItemsList extends StatelessWidget {
  final List<ActiveOrderItem> items;

  const _ItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(item.name, style: textTheme.bodySmall),
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
            )
            .toList(),
      ),
    );
  }
}

// ─── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Drag handle ───────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
