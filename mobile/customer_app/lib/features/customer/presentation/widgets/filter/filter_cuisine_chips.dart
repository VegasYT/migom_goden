import 'package:flutter/material.dart';

import 'filter_section_label.dart';

class FilterCuisineChips extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const FilterCuisineChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _cuisines = [
    ('🍕', 'Пицца'),
    ('🍣', 'Суши'),
    ('🍔', 'Бургеры'),
    ('🥗', 'Салаты'),
    ('🍜', 'Лапша'),
    ('🌮', 'Тако'),
    ('☕', 'Кофе'),
    ('🧁', 'Десерты'),
    ('🥩', 'Мясо'),
    ('🥟', 'Пельмени'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionLabel('Кухня'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cuisines.map(((String, String) c) {
            final isSelected = selected.contains(c.$2);

            return GestureDetector(
              onTap: () {
                final next = Set<String>.from(selected);
                if (isSelected) {
                  next.remove(c.$2);
                } else {
                  next.add(c.$2);
                }
                onChanged(next);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    Text(c.$1, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      c.$2,
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
