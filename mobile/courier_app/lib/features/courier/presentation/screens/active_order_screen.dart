import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/active_order_model.dart';
import '../providers/active_order_provider.dart';
import '../widgets/active_order/order_info_sheet.dart';
import '../widgets/active_order/order_route_map.dart';
import 'awaiting_confirmation_screen.dart';

class ActiveOrderScreen extends ConsumerWidget {
  const ActiveOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(activeOrderProvider);

    if (orderState == null) {
      return const _NoOrderView();
    }

    if (orderState.stage == ActiveOrderStage.awaitingConfirmation) {
      return const AwaitingConfirmationScreen();
    }

    if (orderState.stage == ActiveOrderStage.delivered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeOrderProvider.notifier).clear();
        context.go('/home');
      });
      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Full-screen map
            Positioned.fill(
              child: OrderRouteMap(
                order: orderState.order,
                stage: orderState.stage,
              ),
            ),

            // Top app bar overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _MapAppBar(orderId: orderState.order.id),
            ),

          // Bottom info sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OrderInfoSheet(
              orderState: orderState,
              onPickedUp: () =>
                  ref.read(activeOrderProvider.notifier).pickedUp(),
              onDelivered: () =>
                  ref.read(activeOrderProvider.notifier).delivered(),
            ),
          ),
        ],
      ),
    ));
  }
}

// ─── Map app bar overlay ───────────────────────────────────────────────────────

class _MapAppBar extends StatelessWidget {
  final String orderId;

  const _MapAppBar({required this.orderId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: _GlassPill(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delivery_dining_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Заказ $orderId',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _GlassPill extends StatelessWidget {
  final Widget child;

  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── No order view ─────────────────────────────────────────────────────────────

class _NoOrderView extends StatelessWidget {
  const _NoOrderView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Text(
          'Нет активного заказа',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
