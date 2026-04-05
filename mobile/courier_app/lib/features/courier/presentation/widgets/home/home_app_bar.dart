import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/courier_profile_provider.dart';

class CourierAppBar extends ConsumerWidget {
  const CourierAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(courierProfileSyncProvider);

    final initials = profile.name.trim().isEmpty
        ? '?'
        : profile.name
            .trim()
            .split(' ')
            .where((s) => s.isNotEmpty)
            .take(2)
            .map((s) => s[0].toUpperCase())
            .join();

    final firstName = profile.name.trim().isEmpty
        ? 'Курьер'
        : profile.name.trim().split(' ').first;

    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Добро пожаловать',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              Text(
                firstName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
