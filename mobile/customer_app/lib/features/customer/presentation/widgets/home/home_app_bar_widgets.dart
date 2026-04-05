import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/address_provider.dart';
import '../../providers/filter_provider.dart';
import '../../screens/address_select_screen.dart';
import '../../screens/filter_sheet.dart';

class DeliveryAddressBar extends ConsumerWidget {
  const DeliveryAddressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final defaultAddress = ref.watch(defaultAddressProvider);
    final addressText = defaultAddress?.street ?? 'Выберите адрес';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AddressSelectScreen(selectionMode: true),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Доставка на',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        addressText,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: colorScheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSearchBar extends ConsumerWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeCount = ref.watch(filterProvider).activeCount;
    final hasFilters = activeCount > 0;

    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFilters ? colorScheme.primary : colorScheme.outlineVariant,
            width: hasFilters ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Text(
              'Ресторан, блюдо или кухня...',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => FilterSheet.show(context),
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasFilters
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: hasFilters
                          ? colorScheme.onPrimary
                          : colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasFilters ? 'Фильтр · $activeCount' : 'Фильтр',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasFilters
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
