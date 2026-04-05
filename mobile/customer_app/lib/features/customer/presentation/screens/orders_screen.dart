import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/websocket_provider.dart';
import '../../domain/order_model.dart';
import '../providers/orders_provider.dart';
import '../widgets/orders/active_order_card.dart';
import '../widgets/orders/active_order_expanded.dart';
import '../widgets/orders/past_order_card.dart';
import 'past_order_detail_sheet.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    // Обновляем заказы при изменении статуса через WebSocket
    ref.listenManual(orderStatusEventProvider, (_, __) {
      ref.invalidate(ordersProvider);
    });
    ref.listenManual(courierAssignedEventProvider, (_, __) {
      ref.invalidate(ordersProvider);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _expand() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = true);
    _controller.forward();
  }

  void _collapse() {
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      if (mounted) setState(() => _expanded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeOrder = ref.watch(activeOrderProvider);
    final pastOrdersAsync = ref.watch(pastOrdersListProvider);

    return pastOrdersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (pastOrders) => Stack(
        children: [
          _OrdersList(
            activeOrder: activeOrder,
            pastOrders: pastOrders,
            onExpandTap: _expand,
          ),
          if (_expanded && activeOrder != null)
            ActiveOrderExpanded(
              order: activeOrder,
              animation: _animation,
              onClose: _collapse,
            ),
        ],
      ),
    );
  }
}

// ─── Список заказов ────────────────────────────────────────────────────────────

class _OrdersList extends ConsumerWidget {
  final ActiveOrderModel? activeOrder;
  final List<PastOrderModel> pastOrders;
  final VoidCallback onExpandTap;

  const _OrdersList({
    required this.activeOrder,
    required this.pastOrders,
    required this.onExpandTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

        if (activeOrder != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Активный заказ',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ActiveOrderCard(
              order: activeOrder!,
              onTap: onExpandTap,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],

        if (pastOrders.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'История заказов',
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
                    bottom: i < pastOrders.length - 1 ? 10 : 0,
                  ),
                  child: PastOrderCard(
                    order: pastOrders[i],
                    onTap: () =>
                        PastOrderDetailSheet.show(context, pastOrders[i]),
                  ),
                ),
                childCount: pastOrders.length,
              ),
            ),
          ),
        ],

        if (activeOrder == null && pastOrders.isEmpty)
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
            'Заказов пока нет',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Сделайте первый заказ\nи он появится здесь',
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
