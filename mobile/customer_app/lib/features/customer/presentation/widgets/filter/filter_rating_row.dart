import 'package:flutter/material.dart';

import 'filter_section_label.dart';

class FilterRatingRow extends StatelessWidget {
  final double selected; // 0 = любой
  final ValueChanged<double> onChanged;

  const FilterRatingRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _options = [0.0, 4.0, 4.5, 4.8];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterSectionLabel('Минимальный рейтинг'),
        Row(
          spacing: 8,
          children: _options.map((rating) {
            final isSelected = selected == rating;
            final label =
                rating == 0 ? 'Любой' : '${rating.toStringAsFixed(1)}+';

            return GestureDetector(
              onTap: () => onChanged(rating),
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
                    if (rating > 0) ...[
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label,
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
