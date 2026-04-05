import 'package:flutter/material.dart';

import '../../../domain/payment_method_model.dart';

class PaymentMethodTile extends StatelessWidget {
  final PaymentMethodModel method;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _PaymentIcon(type: method.type, isSelected: isSelected),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.title,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (method.isDefault && !selectionMode) ...[
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
                  if (method.subtitle != null)
                    Text(
                      method.subtitle!,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
              )
            else
              Icon(Icons.chevron_right_rounded, color: cs.outlineVariant),
          ],
        ),
      ),
    );
  }
}

class _PaymentIcon extends StatelessWidget {
  final PaymentType type;
  final bool isSelected;

  const _PaymentIcon({required this.type, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (icon, color) = switch (type) {
      PaymentType.card => (Icons.credit_card_rounded, cs.primary),
      PaymentType.cash => (Icons.payments_outlined, const Color(0xFF22C55E)),
      PaymentType.sbp => (Icons.bolt_rounded, const Color(0xFF3B82F6)),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: 0.15)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: isSelected ? color : cs.onSurfaceVariant, size: 22),
    );
  }
}
