import 'package:flutter/material.dart';

import '../../../domain/address_model.dart';

class CheckoutAddressSelector extends StatelessWidget {
  final AddressModel selected;
  final List<AddressModel> addresses;
  final ValueChanged<AddressModel> onSelect;

  const CheckoutAddressSelector({
    super.key,
    required this.selected,
    required this.addresses,
    required this.onSelect,
  });

  void _showPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите адрес',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ...addresses.map((a) {
              final isSelected = a.id == selected.id;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(a.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(a.fullAddress),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                    : null,
                onTap: () {
                  onSelect(a);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected.fullAddress,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  if (selected.comment != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      selected.comment!,
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
