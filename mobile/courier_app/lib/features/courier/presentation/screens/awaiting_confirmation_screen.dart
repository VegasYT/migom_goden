import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/active_order_provider.dart';

class AwaitingConfirmationScreen extends ConsumerWidget {
  const AwaitingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(),
                _PulsingIcon(color: cs.primary),
                const SizedBox(height: 32),
                Text(
                  'Ожидаем подтверждения',
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Клиент подтверждает получение заказа.\nЭто займёт совсем немного времени.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing icon ──────────────────────────────────────────────────────────────

class _PulsingIcon extends StatefulWidget {
  final Color color;
  const _PulsingIcon({required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.90, end: 1.10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: [
          // outer pulse ring
          Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: _opacity.value * 0.25),
              ),
            ),
          ),
          // inner circle
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              size: 40,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
