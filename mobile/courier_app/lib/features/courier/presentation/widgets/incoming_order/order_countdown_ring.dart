import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../providers/incoming_order_provider.dart';

class OrderCountdownRing extends StatelessWidget {
  final int secondsLeft;
  final double size;

  const OrderCountdownRing({
    super.key,
    required this.secondsLeft,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = secondsLeft / kOrderTimeoutSeconds;

    final color = switch (progress) {
      > 0.5 => colorScheme.primary,
      > 0.25 => const Color(0xFFF97316),
      _ => colorScheme.error,
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              color: color,
              trackColor: colorScheme.outlineVariant,
            ),
          ),
          Text(
            '$secondsLeft',
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final strokeWidth = 3.5;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
