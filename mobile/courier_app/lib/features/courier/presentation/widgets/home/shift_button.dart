import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/shift_provider.dart';

class ShiftButton extends ConsumerStatefulWidget {
  const ShiftButton({super.key});

  @override
  ConsumerState<ShiftButton> createState() => _ShiftButtonState();
}

class _ShiftButtonState extends ConsumerState<ShiftButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onShiftToggle(ShiftState shift) {
    HapticFeedback.heavyImpact();
    final notifier = ref.read(shiftProvider.notifier);
    if (shift.isIdle) {
      notifier.startShift();
      _pulseController.repeat(reverse: true);
    } else if (shift.isActive) {
      notifier.pauseShift();
      _pulseController.stop();
      _pulseController.reset();
    } else {
      notifier.resumeShift();
      _pulseController.repeat(reverse: true);
    }
  }

  void _onEndShift() {
    HapticFeedback.heavyImpact();
    showDialog<bool>(
      context: context,
      builder: (ctx) => _EndShiftDialog(
        onConfirm: () {
          ref.read(shiftProvider.notifier).endShift();
          _pulseController.stop();
          _pulseController.reset();
          Navigator.of(ctx).pop();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shift = ref.watch(shiftProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Sync animation with state
    if (shift.isActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    final buttonColor = shift.isIdle
        ? colorScheme.primary
        : shift.isActive
            ? const Color(0xFFF97316)
            : colorScheme.primary;

    final buttonLabel = shift.isIdle
        ? 'Начать смену'
        : shift.isActive
            ? 'Пауза'
            : 'Продолжить';

    final buttonIcon = shift.isIdle
        ? Icons.play_arrow_rounded
        : shift.isActive
            ? Icons.pause_rounded
            : Icons.play_arrow_rounded;

    return Column(
      children: [
        // Main pulsing circle button
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            final scale = shift.isActive ? _pulseAnim.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: buttonColor.withValues(alpha: shift.isActive ? 0.12 : 0.06),
                ),
              ),
              // Middle ring
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: buttonColor.withValues(alpha: shift.isActive ? 0.18 : 0.10),
                ),
              ),
              // Inner button
              GestureDetector(
                onTap: () => _onShiftToggle(shift),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: buttonColor,
                    boxShadow: [
                      BoxShadow(
                        color: buttonColor.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(buttonIcon, color: Colors.white, size: 32),
                      const SizedBox(height: 2),
                      Text(
                        buttonLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Status label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: shift.isIdle
              ? Text(
                  key: const ValueKey('idle'),
                  'Нажмите, чтобы начать смену',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : _ShiftTimerLabel(key: const ValueKey('active'), shift: shift),
        ),

        // End shift button - only when not idle
        if (!shift.isIdle) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _onEndShift,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop_rounded, size: 14, color: colorScheme.error),
                  const SizedBox(width: 6),
                  Text(
                    'Завершить смену',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Live timer label ─────────────────────────────────────────────────────────

class _ShiftTimerLabel extends StatelessWidget {
  final ShiftState shift;
  const _ShiftTimerLabel({super.key, required this.shift});

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPaused = shift.status == ShiftStatus.paused;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPaused ? const Color(0xFFF97316) : colorScheme.primary,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isPaused ? 'Пауза · ${_format(shift.elapsed)}' : _format(shift.elapsed),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ─── End shift confirmation dialog ────────────────────────────────────────────

class _EndShiftDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _EndShiftDialog({required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.stop_circle_rounded, size: 28, color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Завершить смену?',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'После завершения вы перестанете получать заказы.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: colorScheme.outline),
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Завершить', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
