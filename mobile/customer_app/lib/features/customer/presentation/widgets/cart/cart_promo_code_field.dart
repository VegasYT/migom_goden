import 'package:flutter/material.dart';

class CartPromoCodeField extends StatelessWidget {
  final TextEditingController controller;
  final bool applied;
  final bool error;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const CartPromoCodeField({
    super.key,
    required this.controller,
    required this.applied,
    required this.error,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: applied
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: applied
              ? colorScheme.primary
              : error
                  ? colorScheme.error
                  : colorScheme.outlineVariant,
          width: applied || error ? 1.5 : 0.8,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(
              applied
                  ? Icons.local_offer_rounded
                  : Icons.confirmation_number_outlined,
              size: 18,
              color: applied ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: applied
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(
                      'Промокод «${controller.text.toUpperCase()}» применён - скидка 20%',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Введите промокод',
                      hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      errorText: error ? 'Промокод не найден' : null,
                      errorStyle:
                          TextStyle(color: colorScheme.error, fontSize: 11),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: applied
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: colorScheme.onSurfaceVariant),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                  )
                : TextButton(
                    onPressed: onApply,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                    ),
                    child:
                        const Text('Применить', style: TextStyle(fontSize: 13)),
                  ),
          ),
        ],
      ),
    );
  }
}
