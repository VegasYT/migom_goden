import 'package:flutter/material.dart';

class CheckoutSummary extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final bool isDelivery;

  const CheckoutSummary({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.isDelivery,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Товары',
            value: '${subtotal.toStringAsFixed(0)}₽',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: isDelivery ? 'Доставка' : 'Самовывоз',
            value: deliveryFee == 0
                ? 'Бесплатно'
                : '${deliveryFee.toStringAsFixed(0)}₽',
            valueColor: deliveryFee == 0 ? colorScheme.primary : null,
          ),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Скидка по промокоду',
              value: '−${discount.toStringAsFixed(0)}₽',
              valueColor: colorScheme.primary,
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: colorScheme.outlineVariant, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'К оплате',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${total.toStringAsFixed(0)}₽',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          value,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
