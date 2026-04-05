import 'package:flutter/material.dart';

import '../../../domain/filter_model.dart';
import 'filter_section_label.dart';

class FilterSortRow extends StatelessWidget {
  final SortOption selected;
  final ValueChanged<SortOption> onChanged;

  const FilterSortRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _options = [
    (SortOption.popular, 'Популярные', Icons.local_fire_department_rounded),
    (SortOption.rating, 'По рейтингу', Icons.star_rounded),
    (SortOption.deliveryTime, 'Быстрее', Icons.access_time_rounded),
    (SortOption.deliveryPrice, 'Дешевле', Icons.delivery_dining_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionLabel('Сортировка'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map(((SortOption, String, IconData) opt) {
            final isSelected = selected == opt.$1;
            return GestureDetector(
              onTap: () => onChanged(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.$3,
                      size: 15,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
