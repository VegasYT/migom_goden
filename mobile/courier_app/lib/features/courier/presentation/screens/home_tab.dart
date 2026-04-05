import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/incoming_order_provider.dart';
import '../providers/shift_provider.dart';
import '../widgets/home/courier_info_cards.dart';
import '../widgets/home/home_app_bar.dart';
import '../widgets/home/last_shift_summary.dart';
import '../widgets/home/shift_button.dart';
import '../widgets/home/shift_stats_row.dart';
import '../widgets/home/weekly_earnings_chart.dart';
import 'incoming_order_sheet.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Show incoming order sheet when WS delivers an offer
    ref.listen<IncomingOrderState>(incomingOrderProvider, (previous, next) {
      if (previous?.status != IncomingOrderStatus.pending &&
          next.status == IncomingOrderStatus.pending) {
        showIncomingOrderSheet(context);
      }
    });

    final shift = ref.watch(shiftProvider);

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 16,
          title: const CourierAppBar(),
          actions: const [
            _NotificationsButton(),
            SizedBox(width: 4),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Shift status header card
                _ShiftStatusCard(isActive: shift.isActive),

                const SizedBox(height: 28),

                // Central shift button
                const Center(child: ShiftButton()),

                const SizedBox(height: 24),

                // Stats (visible when shift started)
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: !shift.isIdle
                      ? Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                  width: 0.8,
                                ),
                              ),
                              child: const ShiftStatsRow(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                // Info cards
                const CourierInfoCards(),

                const SizedBox(height: 16),

                // Last shift summary - shown only when idle
                if (shift.isIdle) ...[
                  const LastShiftSummary(),
                  const SizedBox(height: 16),
                ],

                // Weekly earnings chart
                const WeeklyEarningsChart(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shift status header card ─────────────────────────────────────────────────



class _ShiftStatusCard extends StatelessWidget {
  final bool isActive;
  const _ShiftStatusCard({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final bgColor = isActive
        ? colorScheme.primary.withValues(alpha: 0.08)
        : colorScheme.surfaceContainerLow;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Смена активна · Принимаю заказы' : 'Не на смене',
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notifications button ─────────────────────────────────────────────────────

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Mock: 2 unread notifications
    const unread = 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {},
        ),
        if (unread > 0)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
