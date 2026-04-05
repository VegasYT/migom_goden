import 'package:flutter/material.dart';

import '../../providers/active_order_provider.dart';

class DeliveryTimer extends StatelessWidget {
  final int secondsRemaining;

  const DeliveryTimer({super.key, required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final display = formatCountdown(secondsRemaining);

    final color = display.isOverdue ? colorScheme.error : colorScheme.primary;
    final bgColor = color.withValues(alpha: 0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            display.isOverdue
                ? Icons.warning_amber_rounded
                : Icons.access_time_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            display.text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
