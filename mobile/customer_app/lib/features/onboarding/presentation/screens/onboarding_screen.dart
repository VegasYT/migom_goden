import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _bgController;
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      title: 'Лучшие рестораны\nрядом с вами',
      subtitle: 'Сотни заведений в вашем городе - выбирайте любимую кухню и заказывайте в пару касаний.',
      illustration: _IllustrationType.restaurants,
      gradient: [Color(0xFF4ADE80), Color(0xFF22C55E)],
    ),
    _OnboardingData(
      title: 'Отслеживайте\nдоставку live',
      subtitle: 'Видите курьера на карте в реальном времени. Знаете точное время прибытия.',
      illustration: _IllustrationType.delivery,
      gradient: [Color(0xFF34D399), Color(0xFF059669)],
    ),
    _OnboardingData(
      title: 'Быстро,\nудобно, вкусно',
      subtitle: 'Оформите заказ за 30 секунд. Оплата онлайн или наличными при получении.',
      illustration: _IllustrationType.easy,
      gradient: [Color(0xFF6EE7B7), Color(0xFF10B981)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/login');
    }
  }

  void _skip() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isLast = _currentPage == _pages.length - 1;
    final page = _pages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background - top half
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            height: size.height * 0.58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: page.gradient,
              ),
            ),
          ),

          // Bottom half - surface color
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.46,
              color: colorScheme.surface,
            ),
          ),

          // Decorative blobs on gradient
          _AnimatedBlobs(controller: _bgController),

          // Card with rounded top sitting on gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.48,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page counter
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          '${_currentPage + 1} / ${_pages.length}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _skip,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.9),
                          ),
                          child: const Text('Пропустить'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Illustration area - upper part on gradient
                Expanded(
                  flex: 10,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => _OnboardingPage(
                      data: _pages[i],
                      isActive: i == _currentPage,
                    ),
                  ),
                ),

                // Bottom card content
                SizedBox(
                  height: size.height * 0.38,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dots
                        Row(
                          children: List.generate(
                            _pages.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(right: 6),
                              width: i == _currentPage ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _currentPage
                                    ? colorScheme.primary
                                    : colorScheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Align(
                            key: ValueKey(_currentPage),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              page.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                    height: 1.15,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Text(
                            key: ValueKey('sub$_currentPage'),
                            page.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.6,
                                ),
                          ),
                        ),

                        const Spacer(),

                        // Button row
                        Row(
                          children: [
                            // Prev dot button
                            if (_currentPage > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _CircleButton(
                                  icon: Icons.arrow_back_rounded,
                                  onPressed: () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOutCubic,
                                  ),
                                  colorScheme: colorScheme,
                                ),
                              ),

                            // Next / Start
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _next,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isLast ? 'Начать' : 'Далее',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isLast
                                            ? Icons.rocket_launch_rounded
                                            : Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated blobs ───────────────────────────────────────────────────────────

class _AnimatedBlobs extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBlobs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          children: [
            Positioned(
              top: -60 + t * 30,
              right: -40 + t * 20,
              child: _Blob(200, Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              top: 80 - t * 20,
              left: -60 + t * 15,
              child: _Blob(160, Colors.white.withValues(alpha: 0.07)),
            ),
            Positioned(
              top: 200 + t * 10,
              right: 20 - t * 30,
              child: _Blob(100, Colors.white.withValues(alpha: 0.06)),
            ),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ─── Circle back button ───────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;
  const _CircleButton({
    required this.icon,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: colorScheme.outline),
        ),
        child: Icon(icon, size: 22, color: colorScheme.onSurface),
      ),
    );
  }
}

// ─── Page widget ──────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final bool isActive;
  const _OnboardingPage({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.88,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: Center(
        child: _OnboardingIllustration(type: data.illustration),
      ),
    );
  }
}

// ─── Illustration ─────────────────────────────────────────────────────────────

class _OnboardingIllustration extends StatelessWidget {
  final _IllustrationType type;
  const _OnboardingIllustration({required this.type});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 260,
      height: 260,
      child: CustomPaint(
        painter: switch (type) {
          _IllustrationType.restaurants => _RestaurantsPainter(colorScheme),
          _IllustrationType.delivery => _DeliveryPainter(colorScheme),
          _IllustrationType.easy => _EasyPainter(colorScheme),
        },
      ),
    );
  }
}

// ─── Painter 1: Restaurants ───────────────────────────────────────────────────

class _RestaurantsPainter extends CustomPainter {
  final ColorScheme cs;
  _RestaurantsPainter(this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer glow ring
    canvas.drawCircle(
      Offset(cx, cy),
      118,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // White card background
    _drawCard(canvas, Offset(cx, cy), 100, 160, cs);

    // Top colored header strip on card
    final headerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 50, cy - 80, 100, 36),
      const Radius.circular(12),
    );
    canvas.drawRRect(headerRect, Paint()..color = Colors.white.withValues(alpha: 0.3));

    // App bar dots
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(cx - 20 + i * 20.0, cy - 63),
        3.5,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }

    // Menu items
    _drawMenuItem(canvas, cx, cy - 28, cs, icon: Icons.local_pizza_rounded, label: 'Пицца', price: '350₽');
    _drawMenuItem(canvas, cx, cy + 14, cs, icon: Icons.ramen_dining_rounded, label: 'Суши', price: '520₽');
    _drawMenuItem(canvas, cx, cy + 56, cs, icon: Icons.local_cafe_rounded, label: 'Кофе', price: '180₽');

    // Floating badges
    _drawBadge(canvas, Offset(cx + 84, cy - 72), Icons.star_rounded, '4.9', cs, Colors.amber);
    _drawBadge(canvas, Offset(cx - 86, cy + 40), Icons.timer_rounded, '25 мин', cs, cs.primary);
    _drawBadge(canvas, Offset(cx + 82, cy + 52), Icons.local_offer_rounded, '-20%', cs, cs.error);
  }

  void _drawCard(Canvas canvas, Offset center, double w, double h, ColorScheme cs) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w * 2, height: h * 2),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
  }

  void _drawMenuItem(Canvas canvas, double cx, double y, ColorScheme cs,
      {required IconData icon, required String label, required String price}) {
    // Row bg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 46, y, 92, 32),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF4ADE80).withValues(alpha: 0.1),
    );

    // Icon circle
    canvas.drawCircle(
      Offset(cx - 32, y + 16),
      11,
      Paint()..color = const Color(0xFF4ADE80),
    );
    _paintIcon(canvas, Offset(cx - 32, y + 16), icon, Colors.white, 13);

    // Label
    _paintText(canvas, Offset(cx - 16, y + 8), label, cs.onSurface, 9, FontWeight.w600);
    // Price
    _paintText(canvas, Offset(cx - 16, y + 19), price, const Color(0xFF4ADE80), 8, FontWeight.w700);

    // Arrow
    _paintIcon(canvas, Offset(cx + 36, y + 16), Icons.chevron_right_rounded,
        cs.onSurfaceVariant.withValues(alpha: 0.4), 14);
  }

  void _drawBadge(Canvas canvas, Offset center, IconData icon, String label,
      ColorScheme cs, Color color) {
    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(0, 2), width: 72, height: 32),
        const Radius.circular(16),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 72, height: 32),
        const Radius.circular(16),
      ),
      Paint()..color = Colors.white,
    );
    _paintIcon(canvas, Offset(center.dx - 20, center.dy), icon, color, 14);
    _paintText(canvas, Offset(center.dx - 6, center.dy - 6), label, cs.onSurface, 8.5, FontWeight.w700);
  }

  void _paintIcon(Canvas canvas, Offset center, IconData icon, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _paintText(Canvas canvas, Offset topLeft, String text, Color color,
      double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, topLeft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Painter 2: Delivery ─────────────────────────────────────────────────────

class _DeliveryPainter extends CustomPainter {
  final ColorScheme cs;
  _DeliveryPainter(this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Map background card
    final mapRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 10), width: 220, height: 200),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      mapRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(mapRect, Paint()..color = const Color(0xFFE8F5E9));

    // Map grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (int i = 0; i < 6; i++) {
      final y = cy - 80.0 + i * 36;
      canvas.drawLine(Offset(cx - 110, y), Offset(cx + 110, y), gridPaint);
    }
    for (int i = 0; i < 7; i++) {
      final x = cx - 110.0 + i * 36;
      canvas.drawLine(Offset(x, cy - 90), Offset(x, cy + 100), gridPaint);
    }

    // Road
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 90, cy + 20), Offset(cx + 90, cy + 20), roadPaint);
    canvas.drawLine(Offset(cx, cy - 80), Offset(cx, cy + 20), roadPaint);

    // Dashed center line
    final dashPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final x = cx - 70.0 + i * 34;
      canvas.drawLine(Offset(x, cy + 20), Offset(x + 18, cy + 20), dashPaint);
    }

    // Destination pin
    _drawPin(canvas, Offset(cx + 60, cy - 40), cs.error, '🏠');

    // Scooter with courier
    _drawScooter(canvas, Offset(cx - 20, cy + 10), cs);

    // Progress bar (ETA card)
    _drawEtaCard(canvas, Offset(cx, cy - 88), cs);

    // Pulse ring around scooter
    canvas.drawCircle(
      Offset(cx - 20, cy + 10),
      28,
      Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawScooter(Canvas canvas, Offset c, ColorScheme cs) {
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 18), width: 48, height: 10),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Body
    final body = Path()
      ..moveTo(c.dx - 22, c.dy + 8)
      ..lineTo(c.dx - 10, c.dy - 10)
      ..lineTo(c.dx + 8, c.dy - 12)
      ..lineTo(c.dx + 22, c.dy - 2)
      ..lineTo(c.dx + 22, c.dy + 8)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFF4ADE80));

    // Wheels
    for (final dx in [-18.0, 18.0]) {
      canvas.drawCircle(Offset(c.dx + dx, c.dy + 14), 10,
          Paint()..color = const Color(0xFF1A1D27));
      canvas.drawCircle(Offset(c.dx + dx, c.dy + 14), 5,
          Paint()..color = Colors.white);
    }

    // Delivery box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx - 2, c.dy - 20), width: 24, height: 18),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawLine(
      Offset(c.dx - 2, c.dy - 28),
      Offset(c.dx - 2, c.dy - 12),
      Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.5)
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(c.dx - 10, c.dy - 20),
      Offset(c.dx + 6, c.dy - 20),
      Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.5)
        ..strokeWidth = 1.5,
    );

    // Speed lines
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(c.dx - 34 - i * 10, c.dy - 2 + i * 4.0),
        Offset(c.dx - 46 - i * 10, c.dy - 2 + i * 4.0),
        Paint()
          ..color = const Color(0xFF4ADE80).withValues(alpha: 0.6 - i * 0.15)
          ..strokeWidth = 2 - i * 0.3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawPin(Canvas canvas, Offset c, Color color, String emoji) {
    // Shadow
    canvas.drawCircle(
      c + const Offset(0, 2),
      18,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Circle
    canvas.drawCircle(c, 18, Paint()..color = color);
    // Tail
    final path = Path()
      ..moveTo(c.dx - 7, c.dy + 14)
      ..lineTo(c.dx + 7, c.dy + 14)
      ..lineTo(c.dx, c.dy + 28)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    // Emoji
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2 + 1));
  }

  void _drawEtaCard(Canvas canvas, Offset center, ColorScheme cs) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 140, height: 32),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);

    // Icon
    final tp1 = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.access_time_rounded.codePoint),
        style: TextStyle(
          fontSize: 14,
          fontFamily: Icons.access_time_rounded.fontFamily,
          color: const Color(0xFF4ADE80),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(center.dx - 62, center.dy - tp1.height / 2));

    final tp2 = TextPainter(
      text: TextSpan(
        text: 'Доедет через 12 мин',
        style: TextStyle(
          fontSize: 9,
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(center.dx - 44, center.dy - tp2.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Painter 3: Easy ─────────────────────────────────────────────────────────

class _EasyPainter extends CustomPainter {
  final ColorScheme cs;
  _EasyPainter(this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Phone shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 4, cy + 14), width: 140, height: 220),
        const Radius.circular(28),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Phone body
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 10), width: 140, height: 220),
      const Radius.circular(28),
    );
    canvas.drawRRect(phoneRect, Paint()..color = Colors.white);

    // Status bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 70, cy - 100, 140, 28),
        const Radius.circular(28),
      ),
      Paint()..color = const Color(0xFF4ADE80).withValues(alpha: 0.12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 86), width: 40, height: 10),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF4ADE80).withValues(alpha: 0.3),
    );

    // Success animation circle
    canvas.drawCircle(
      Offset(cx, cy - 10),
      44,
      Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(Offset(cx, cy - 10), 38, Paint()..color = const Color(0xFF4ADE80));

    // Checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final checkPath = Path()
      ..moveTo(cx - 14, cy - 10)
      ..lineTo(cx - 2, cy + 10)
      ..lineTo(cx + 16, cy - 22);
    canvas.drawPath(checkPath, checkPaint);

    // Order text stub lines
    _drawLine(canvas, cx, cy + 48, 80, 7, const Color(0xFF4ADE80).withValues(alpha: 0.7));
    _drawLine(canvas, cx, cy + 62, 56, 6, Colors.black.withValues(alpha: 0.1));

    // Pay button at bottom of phone
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 48, cy + 78, 96, 22),
        const Radius.circular(11),
      ),
      Paint()..color = const Color(0xFF4ADE80),
    );
    final payTp = TextPainter(
      text: const TextSpan(
        text: 'Оплачено ✓',
        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    payTp.paint(canvas, Offset(cx - payTp.width / 2, cy + 83));

    // Floating badges
    _drawFloatingBadge(canvas, Offset(cx + 96, cy - 40), '⚡ Быстро', cs);
    _drawFloatingBadge(canvas, Offset(cx - 98, cy + 20), '🔒 Безопасно', cs);

    // Star rating
    for (int i = 0; i < 5; i++) {
      _drawStar(canvas, Offset(cx - 40 + i * 20.0, cy + 36), 6, const Color(0xFFFBBF24));
    }
  }

  void _drawLine(Canvas canvas, double cx, double y, double w, double h, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y), width: w, height: h),
        const Radius.circular(4),
      ),
      Paint()..color = color,
    );
  }

  void _drawFloatingBadge(Canvas canvas, Offset center, String text, ColorScheme cs) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 9, color: cs.onSurface, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final w = tp.width + 20;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: 26),
      const Radius.circular(13),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final angle = (i * 36 - 90) * (math.pi / 180);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Data ─────────────────────────────────────────────────────────────────────

enum _IllustrationType { restaurants, delivery, easy }

class _OnboardingData {
  final String title;
  final String subtitle;
  final _IllustrationType illustration;
  final List<Color> gradient;

  const _OnboardingData({
    required this.title,
    required this.subtitle,
    required this.illustration,
    required this.gradient,
  });
}
