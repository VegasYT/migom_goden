import 'package:flutter/material.dart';

// TODO: replace mock data with real API when /couriers/me/stats is available.
// See COMMENTED_FEATURES.md §1.
import '../../../data/courier_mock_data.dart';

class WeeklyEarningsChart extends StatelessWidget {
  const WeeklyEarningsChart({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // MOCK: weekly earnings not available from API yet
    final data = CourierMockData.weeklyEarnings;

    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final totalWeek = data.fold(0.0, (sum, e) => sum + e.amount);

    // Today = index 3 (Thursday) - mock
    const todayIndex = 3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Заработок за неделю',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${totalWeek.toInt()} ₽',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bar chart
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isToday = i == todayIndex;
                final heightFraction = maxAmount > 0 ? item.amount / maxAmount : 0.0;
                const barMax = 64.0;
                final barHeight = 6 + heightFraction * barMax;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reserved slot for price label - keeps all bars bottom-aligned
                        SizedBox(
                          height: 18,
                          child: isToday && item.amount > 0
                              ? Center(
                                  child: Text(
                                    '${item.amount.toInt()} ₽',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isToday
                                ? colorScheme.primary
                                : item.amount == 0
                                    ? colorScheme.outlineVariant
                                    : colorScheme.primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.day,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isToday
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
