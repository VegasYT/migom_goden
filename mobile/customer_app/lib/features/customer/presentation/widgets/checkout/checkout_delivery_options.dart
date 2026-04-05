import 'package:flutter/material.dart';

class CheckoutDeliveryOptions extends StatelessWidget {
  final bool leaveAtDoor;
  final ValueChanged<bool> onLeaveAtDoor;

  const CheckoutDeliveryOptions({
    super.key,
    required this.leaveAtDoor,
    required this.onLeaveAtDoor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        value: leaveAtDoor,
        onChanged: onLeaveAtDoor,
        title: const Text(
          'Оставить у двери',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          'Курьер оставит заказ у двери',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        activeThumbColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      ),
    );
  }
}
