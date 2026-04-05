import 'package:flutter/material.dart';

import '../../../domain/vehicle_type.dart';

class VehicleOptionTile extends StatelessWidget {
  final VehicleType type;
  final bool selected;
  final VoidCallback onTap;

  const VehicleOptionTile({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                type.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? cs.onPrimaryContainer
                          : cs.onSurface,
                    ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  color: cs.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
