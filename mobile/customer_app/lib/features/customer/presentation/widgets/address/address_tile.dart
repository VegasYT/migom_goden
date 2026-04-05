import 'package:flutter/material.dart';

import '../../../domain/address_model.dart';

class AddressTile extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const AddressTile({
    super.key,
    required this.address,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final icon = switch (address.label) {
      'Дом' => Icons.home_outlined,
      'Работа' => Icons.work_outline_rounded,
      _ => Icons.location_on_outlined,
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.12)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (address.isDefault && !selectionMode) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Основной',
                            style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.fullAddress,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (address.comment != null && address.comment!.isNotEmpty)
                    Text(
                      address.comment!,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (selectionMode)
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? cs.primary : cs.outline,
                size: 22,
              )
            else if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: cs.error, size: 20),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}
