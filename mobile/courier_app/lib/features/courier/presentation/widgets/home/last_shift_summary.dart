import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/shift_provider.dart';

// NOTE: Backend API does not provide earnings/orders per shift.
// ShiftResponse only has started_at, ended_at, is_active.
// This widget shows shift duration from local state only.
// See COMMENTED_FEATURES.md §3.

class LastShiftSummary extends ConsumerWidget {
  const LastShiftSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.12),
            colorScheme.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Статистика смен',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Детальная статистика за смену\nбудет доступна после обновления бэкенда',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
