import 'package:flutter/material.dart';

import '../../../domain/payment_method_model.dart';

IconData paymentTypeIcon(PaymentType type) {
  switch (type) {
    case PaymentType.card:
      return Icons.credit_card_rounded;
    case PaymentType.sbp:
      return Icons.bolt_rounded;
    case PaymentType.cash:
      return Icons.payments_rounded;
  }
}

class CheckoutPaymentSelector extends StatelessWidget {
  final PaymentMethodModel selected;
  final List<PaymentMethodModel> methods;
  final ValueChanged<PaymentMethodModel> onSelect;

  const CheckoutPaymentSelector({
    super.key,
    required this.selected,
    required this.methods,
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
              'Способ оплаты',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ...methods.map((m) {
              final isSelected = m.id == selected.id;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  child: Icon(
                    paymentTypeIcon(m.type),
                    size: 18,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(m.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: m.subtitle != null ? Text(m.subtitle!) : null,
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                    : null,
                onTap: () {
                  onSelect(m);
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
            Icon(paymentTypeIcon(selected.type), color: colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  if (selected.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      selected.subtitle!,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
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
