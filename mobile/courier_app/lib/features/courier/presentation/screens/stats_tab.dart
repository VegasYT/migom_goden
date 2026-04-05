import 'package:flutter/material.dart';

import '../widgets/stats/period_selector.dart';
import '../widgets/stats/earnings_header.dart';
import '../widgets/stats/metrics_grid.dart';
import '../widgets/home/weekly_earnings_chart.dart';
import '../widgets/stats/shift_history_list.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(
            'Статистика',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
          forceElevated: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const PeriodSelector(),
              const SizedBox(height: 14),
              const EarningsHeader(),
              const SizedBox(height: 14),
              const MetricsGrid(),
              const SizedBox(height: 16),
              _SectionLabel(label: 'Заработок за неделю', textTheme: textTheme, colorScheme: colorScheme),
              const SizedBox(height: 10),
              const WeeklyEarningsChart(),
              const SizedBox(height: 16),
              const ShiftHistoryList(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _SectionLabel({
    required this.label,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }
}
