import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/order_history_model.dart';
import '../providers/order_history_provider.dart';
import '../widgets/orders/delivered_order_card.dart';

class OrderHistoryTab extends ConsumerWidget {
  const OrderHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderHistoryProvider);
    final orders = ordersAsync.valueOrNull ?? const [];
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Заказы'),
        ),

        if (orders.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'История доставок',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: EdgeInsets.only(
                    bottom: i < orders.length - 1 ? 10 : 0,
                  ),
                  child: DeliveredOrderCard(
                    order: orders[i],
                    onTap: () => _DeliveredOrderDetailSheet.show(
                      context,
                      orders[i],
                    ),
                  ),
                ),
                childCount: orders.length,
              ),
            ),
          ),
        ],

        if (orders.isEmpty)
          const SliverFillRemaining(child: _OrdersEmpty()),
      ],
    );
  }
}

// ─── Пустое состояние ─────────────────────────────────────────────────────────

class _OrdersEmpty extends StatelessWidget {
  const _OrdersEmpty();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Доставок пока нет',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Завершённые доставки\nпоявятся здесь',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Детальный bottom sheet ───────────────────────────────────────────────────

class _DeliveredOrderDetailSheet extends StatelessWidget {
  final DeliveredOrderModel order;

  const _DeliveredOrderDetailSheet({required this.order});

  static Future<void> show(BuildContext context, DeliveredOrderModel order) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeliveredOrderDetailSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Шапка
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                order.restaurantEmoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.restaurantName,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Заказ №${order.id} · ${order.date}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Доставлен',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Адрес доставки
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.customerAddress,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            '${order.distanceKm.toStringAsFixed(1)} км',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Позиции
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final item = order.items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.name,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: order.items.length,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    children: [
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Вознаграждение',
                              style: textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${order.payment.toStringAsFixed(0)} ₽',
                            style: textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Закрыть'),
                        ),
                      ),
                      SizedBox(height: bottomPadding + 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
