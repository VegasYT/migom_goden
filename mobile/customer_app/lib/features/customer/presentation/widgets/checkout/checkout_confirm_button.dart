import 'package:flutter/material.dart';

class CheckoutConfirmButton extends StatelessWidget {
  final double total;
  final VoidCallback onPressed;
  final bool isLoading;

  const CheckoutConfirmButton({
    super.key,
    required this.total,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.check_circle_rounded, size: 20),
            const SizedBox(width: 10),
            Text(
              isLoading ? 'Оформляем...' : 'Подтвердить заказ',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimary,
              ),
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
