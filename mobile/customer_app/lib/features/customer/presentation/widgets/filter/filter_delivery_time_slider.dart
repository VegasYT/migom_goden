import 'package:flutter/material.dart';

import 'filter_section_label.dart';

class FilterDeliveryTimeSlider extends StatelessWidget {
  final int value; // 0 = любое
  final ValueChanged<int> onChanged;

  const FilterDeliveryTimeSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: FilterSectionLabel('Время доставки')),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                value == 0 ? 'Любое' : 'до $value мин',
                key: ValueKey(value),
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.outlineVariant,
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 4,
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            min: 0,
            max: 60,
            divisions: 6,
            value: value.toDouble(),
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Любое', '10', '20', '30', '40', '50', '60 мин']
                .map(
                  (l) => Text(
                    l,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
