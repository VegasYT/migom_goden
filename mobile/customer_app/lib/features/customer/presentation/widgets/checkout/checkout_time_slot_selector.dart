import 'package:flutter/material.dart';

class CheckoutTimeSlotSelector extends StatelessWidget {
  final List<String> slots;
  final int selected;
  final ValueChanged<int> onSelect;

  const CheckoutTimeSlotSelector({
    super.key,
    required this.slots,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(slots.length, (i) {
        final isSelected = selected == i;
        return ChoiceChip(
          label: Text(slots[i]),
          selected: isSelected,
          onSelected: (_) => onSelect(i),
          selectedColor: colorScheme.primary.withValues(alpha: 0.15),
          backgroundColor: colorScheme.surfaceContainerLowest,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          showCheckmark: false,
        );
      }),
    );
  }
}
