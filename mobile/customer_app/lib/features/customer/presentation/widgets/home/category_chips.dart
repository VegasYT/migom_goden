import 'package:flutter/material.dart';

const _categories = [
  (emoji: '🍕', label: 'Пицца'),
  (emoji: '🍣', label: 'Суши'),
  (emoji: '🍔', label: 'Бургеры'),
  (emoji: '🥗', label: 'Салаты'),
  (emoji: '🍜', label: 'Лапша'),
  (emoji: '🌮', label: 'Тако'),
  (emoji: '☕', label: 'Кофе'),
  (emoji: '🧁', label: 'Десерты'),
];

class CategoryChips extends StatefulWidget {
  const CategoryChips({super.key});

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = _categories;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = i == _selected;

          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
