import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Swipe-to-accept slider. Drag the thumb right past [threshold] to confirm.
/// Releases before threshold → thumb snaps back with spring animation.
class AcceptSlider extends StatefulWidget {
  final VoidCallback onAccepted;
  final double threshold;

  const AcceptSlider({
    super.key,
    required this.onAccepted,
    this.threshold = 0.82,
  });

  @override
  State<AcceptSlider> createState() => _AcceptSliderState();
}

class _AcceptSliderState extends State<AcceptSlider>
    with SingleTickerProviderStateMixin {
  // Raw drag progress 0..1, updated on every pan event.
  double _dragProgress = 0.0;

  // Progress used for rendering; during snap-back this is driven by animation.
  double _renderProgress = 0.0;

  bool _completed = false;
  bool _snappingBack = false;

  late final AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    // Single listener - always reads _snapAnimation.value (reassigned each snap).
    _snapController.addListener(_onSnapTick);
    _snapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _snappingBack = false;
          _renderProgress = 0.0;
          _dragProgress = 0.0;
        });
      }
    });
  }

  void _onSnapTick() {
    if (_snappingBack && !_completed) {
      setState(() => _renderProgress = _snapAnimation.value);
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d, double availableTravel) {
    if (_completed) return;
    // Cancel any ongoing snap-back when the user grabs the thumb again.
    if (_snappingBack) {
      _snapController.stop();
      _snappingBack = false;
    }
    setState(() {
      _dragProgress =
          (_dragProgress + d.delta.dx / availableTravel).clamp(0.0, 1.0);
      _renderProgress = _dragProgress;
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_completed) return;

    if (_dragProgress >= widget.threshold) {
      setState(() {
        _renderProgress = 1.0;
        _completed = true;
      });
      HapticFeedback.heavyImpact();
      widget.onAccepted();
    } else {
      // Spring back from current position to 0.
      _snapAnimation = Tween<double>(
        begin: _dragProgress,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _snapController,
        curve: Curves.easeOutCubic,
      ));
      _snappingBack = true;
      _snapController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Track height defines everything - thumb is a perfect circle inside it.
    const trackHeight = 64.0;
    const pad = 5.0;
    // Thumb side = track height minus equal padding top+bottom → perfect circle.
    const thumbSide = trackHeight - pad * 2; // 54px - perfect circle

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        // Travel is symmetric: thumb starts at pad, ends at trackWidth - pad - thumbSide.
        final availableTravel = trackWidth - thumbSide - pad * 2;
        final thumbLeft = pad + _renderProgress * availableTravel;

        final labelOpacity =
            _completed ? 0.0 : (1.0 - _renderProgress * 2.0).clamp(0.0, 1.0);

        return SizedBox(
          height: trackHeight,
          child: GestureDetector(
            onHorizontalDragUpdate: (d) => _onPanUpdate(d, availableTravel),
            onHorizontalDragEnd: _onPanEnd,
            // No Clip on the outer Stack - shadow can bleed outside the track.
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Track background ──────────────────────────────────────
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                          alpha: _completed ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                  ),
                ),

                // ── Progress fill (clipped to track shape) ────────────────
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: (thumbLeft + thumbSide / 2).clamp(0.0, trackWidth),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                    child: ColoredBox(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ),

                // ── Hint label ────────────────────────────────────────────
                Positioned.fill(
                  child: Opacity(
                    opacity: labelOpacity,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: thumbSide + 12),
                          Icon(Icons.chevron_right_rounded,
                              size: 15,
                              color: colorScheme.primary
                                  .withValues(alpha: 0.45)),
                          Icon(Icons.chevron_right_rounded,
                              size: 15,
                              color: colorScheme.primary
                                  .withValues(alpha: 0.28)),
                          const SizedBox(width: 4),
                          Text(
                            'Смахните, чтобы принять',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Thumb - perfect circle, shadow outside track ──────────
                Positioned(
                  left: thumbLeft,
                  top: pad,
                  width: thumbSide,
                  height: thumbSide,
                  child: AnimatedContainer(
                    duration: _completed
                        ? const Duration(milliseconds: 180)
                        : Duration.zero,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _completed
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: colorScheme.onPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
