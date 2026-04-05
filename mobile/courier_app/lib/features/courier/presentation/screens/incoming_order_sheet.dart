import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/order_sound_service.dart';
import '../providers/incoming_order_provider.dart';
import '../widgets/incoming_order/accept_slider.dart';
import '../widgets/incoming_order/order_countdown_ring.dart';
import '../widgets/incoming_order/order_details_card.dart';

/// Shows a modal bottom sheet with the incoming order.
/// Handles sound playback lifecycle.
Future<void> showIncomingOrderSheet(BuildContext context) {
  // Capture the navigator that owns the bottom sheet (the root navigator
  // used by showModalBottomSheet) before entering the builder, so the sheet
  // can pop itself without touching GoRouter's navigator.
  final sheetNavigator = Navigator.of(context, rootNavigator: true);

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _IncomingOrderSheet(sheetNavigator: sheetNavigator),
  );
}

class _IncomingOrderSheet extends ConsumerStatefulWidget {
  final NavigatorState sheetNavigator;

  const _IncomingOrderSheet({required this.sheetNavigator});

  @override
  ConsumerState<_IncomingOrderSheet> createState() =>
      _IncomingOrderSheetState();
}

class _IncomingOrderSheetState extends ConsumerState<_IncomingOrderSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    _entryController.forward();
    // Sound is started in IncomingOrderNotifier.receive(); no need to start here.
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _closeAndDismiss() {
    OrderSoundService.stop();
    ref.read(incomingOrderProvider.notifier).dismiss();
    if (widget.sheetNavigator.canPop()) {
      widget.sheetNavigator.pop();
    }
  }

  void _accept() {
    // accept() triggers the global listener in _AppState which starts the
    // active order and navigates to /active-order.
    ref.read(incomingOrderProvider.notifier).accept();
    // Close the sheet immediately; navigation happens via global listener.
    if (widget.sheetNavigator.canPop()) widget.sheetNavigator.pop();
  }

  void _decline() {
    ref.read(incomingOrderProvider.notifier).decline();
    OrderSoundService.stop();
    _closeAndDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(incomingOrderProvider);
    final order = orderState.order;
    if (order == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Auto-close when timed out / declined externally
    ref.listen(incomingOrderProvider, (_, next) {
      if (next.status == IncomingOrderStatus.declined && mounted) {
        OrderSoundService.stop();
        if (widget.sheetNavigator.canPop()) {
          widget.sheetNavigator.pop();
        }
        ref.read(incomingOrderProvider.notifier).dismiss();
      }
    });

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_slideAnim),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row: label + order id + countdown ring
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Новый заказ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Заказ ${order.id}',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OrderCountdownRing(secondsLeft: orderState.secondsLeft),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Details card
                  OrderDetailsCard(order: order),

                  const SizedBox(height: 20),

                  // Accept slider
                  AcceptSlider(onAccepted: _accept),

                  const SizedBox(height: 12),

                  // Decline button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _decline,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Отказаться',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
