import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/checkout_screen.dart';

class CartOrderSummary extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final int deliveryType;
  final double freeDeliveryFrom;

  const CartOrderSummary({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.deliveryType,
    required this.freeDeliveryFrom,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final remaining = freeDeliveryFrom - subtotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Итого',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          if (deliveryType == 0) ...[
            Row(
              children: [
                Icon(
                  Icons.delivery_dining_rounded,
                  size: 14,
                  color: remaining <= 0
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    remaining <= 0
                        ? 'Бесплатная доставка!'
                        : 'До бесплатной доставки: ${remaining.toStringAsFixed(0)}₽',
                    style: TextStyle(
                      fontSize: 12,
                      color: remaining <= 0
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (subtotal / freeDeliveryFrom).clamp(0.0, 1.0),
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: colorScheme.outlineVariant, height: 1),
            const SizedBox(height: 12),
          ],

          _SummaryRow(label: 'Товары', value: '${subtotal.toStringAsFixed(0)}₽'),
          const SizedBox(height: 8),
          _SummaryRow(
            label: deliveryType == 1 ? 'Самовывоз' : 'Доставка',
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

class CartCheckoutButton extends StatelessWidget {
  final double total;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final int deliveryType;
  final String restaurantName;
  final int? outletId;
  final bool outletLoading;

  const CartCheckoutButton({
    super.key,
    required this.total,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.deliveryType,
    required this.restaurantName,
    this.outletId,
    this.outletLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ready = !outletLoading && outletId != null;

    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: ready
            ? () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      subtotal: subtotal,
                      deliveryFee: deliveryFee,
                      discount: discount,
                      total: total,
                      deliveryType: deliveryType,
                      restaurantName: restaurantName,
                      outletId: outletId,
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.6),
          disabledForegroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (outletLoading)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.shopping_bag_rounded, size: 20),
            const SizedBox(width: 10),
            Text(
              outletLoading ? 'Определяем точку...' : 'Оформить заказ',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${total.toStringAsFixed(0)}₽',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
