import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/courier_mock_data.dart';
import '../../providers/stats_provider.dart';

class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(statsPeriodProvider);
    final colorScheme = Theme.of(context).colorScheme;

    const items = [
      (period: StatsPeriod.today, label: 'Сегодня'),
      (period: StatsPeriod.week, label: 'Неделя'),
      (period: StatsPeriod.month, label: 'Месяц'),
    ];

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: items.map((item) {
          final isActive = item.period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(statsPeriodProvider.notifier).state = item.period;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.surfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                    child: Text(item.label),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
