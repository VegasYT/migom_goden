import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/cart_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dismissible(
      key: Key('cart_item_${item.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_rounded, color: colorScheme.onErrorContainer),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.photoUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _Placeholder(colorScheme: colorScheme),
                    )
                  : _Placeholder(colorScheme: colorScheme),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.price.toStringAsFixed(0)}₽',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QuantityStepper(
              quantity: item.quantity,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Placeholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: colorScheme.primaryContainer,
      child: Icon(Icons.fastfood_rounded,
          color: colorScheme.onPrimaryContainer, size: 28),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: quantity == 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onTap: onDecrement,
            color: quantity == 1 ? colorScheme.error : colorScheme.primary,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _StepButton(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
