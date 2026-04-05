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
      title: 'Работайте\nна своих условиях',
      subtitle:
          'Сами выбираете время и зону доставки. Начните смену в любой момент и зарабатывайте удобно.',
      illustration: _IllustrationType.schedule,
      gradient: [Color(0xFF4ADE80), Color(0xFF22C55E)],
    ),
    _OnboardingData(
      title: 'Навигация\nи маршруты',
      subtitle:
          'Получайте заказы рядом с вами. Встроенная карта покажет оптимальный маршрут до клиента.',
      illustration: _IllustrationType.map,
      gradient: [Color(0xFF34D399), Color(0xFF059669)],
    ),
    _OnboardingData(
      title: 'Заработок\nв реальном времени',
      subtitle:
          'Следите за доходом прямо в приложении. Быстрые выплаты без лишних задержек.',
      illustration: _IllustrationType.earnings,
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
                // Top row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                            foregroundColor:
                                Colors.white.withValues(alpha: 0.9),
                          ),
                          child: const Text('Пропустить'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Illustration
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
                                    : colorScheme.primary
                                        .withValues(alpha: 0.2),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
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
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.6,
                                    ),
                          ),
                        ),

                        const Spacer(),

                        // Button row
                        Row(
                          children: [
                            if (_currentPage > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _CircleButton(
                                  icon: Icons.arrow_back_rounded,
                                  onPressed: () =>
                                      _pageController.previousPage(
                                    duration:
                                        const Duration(milliseconds: 400),
                                    curve: Curves.easeInOutCubic,
                                  ),
                                  colorScheme: colorScheme,
                                ),
                              ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
          _IllustrationType.schedule => _SchedulePainter(colorScheme),
          _IllustrationType.map => _MapPainter(colorScheme),
          _IllustrationType.earnings => _EarningsPainter(colorScheme),
        },
      ),
    );
  }
}

// ─── Painter helpers ──────────────────────────────────────────────────────────

void _paintIcon(
    Canvas canvas, Offset center, IconData icon, Color color, double size) {
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

void _drawCard(
    Canvas canvas, Offset center, double w, double h, double radius) {
  final rect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: center, width: w, height: h),
    Radius.circular(radius),
  );
  canvas.drawRRect(
    rect,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );
  canvas.drawRRect(rect, Paint()..color = Colors.white);
}

// ─── Painter 1: Schedule (shift/time) ─────────────────────────────────────────

class _SchedulePainter extends CustomPainter {
  final ColorScheme cs;
  _SchedulePainter(this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer glow
    canvas.drawCircle(
      Offset(cx, cy),
      118,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Main card (phone-like)
    _drawCard(canvas, Offset(cx, cy + 5), 180, 200, 20);

    // Header strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 90, cy - 95, 180, 44),
        const Radius.circular(20),
      ),
      Paint()..color = const Color(0xFF4ADE80),
    );
    _paintText(canvas, Offset(cx - 52, cy - 84), 'Рабочая смена', Colors.white, 10,
        FontWeight.w700);
    _paintIcon(canvas, Offset(cx + 62, cy - 73), Icons.more_horiz_rounded,
        Colors.white.withValues(alpha: 0.7), 14);

    // Time display
    _paintText(canvas, Offset(cx - 46, cy - 40), '08:30 – 18:00',
        const Color(0xFF4ADE80), 15, FontWeight.w800);

    // Shift status badge
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 12), width: 90, height: 20),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF4ADE80).withValues(alpha: 0.15),
    );
    _paintText(canvas, Offset(cx - 30, cy - 20), '● Активна',
        const Color(0xFF4ADE80), 9, FontWeight.w600);

    // Stats row
    _drawStatChip(canvas, Offset(cx - 52, cy + 14), Icons.local_shipping_rounded,
        '12 заказов', cs);
    _drawStatChip(
        canvas, Offset(cx + 28, cy + 14), Icons.route_rounded, '47 км', cs);

    // Earnings line
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 76, cy + 52, 152, 36),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF4ADE80).withValues(alpha: 0.08),
    );
    _paintIcon(canvas, Offset(cx - 58, cy + 70), Icons.attach_money_rounded,
        const Color(0xFF4ADE80), 16);
    _paintText(canvas, Offset(cx - 42, cy + 58), 'Заработано сегодня',
        cs.onSurfaceVariant, 8, FontWeight.w500);
    _paintText(canvas, Offset(cx - 42, cy + 68), '2 840 ₽',
        const Color(0xFF4ADE80), 11, FontWeight.w800);

    // Floating badges
    _drawBadge(canvas, Offset(cx + 88, cy - 60), Icons.star_rounded, '4.9', cs,
        Colors.amber);
    _drawBadge(canvas, Offset(cx - 90, cy + 50), Icons.timer_rounded, '9 мин', cs,
        const Color(0xFF4ADE80));
  }

  void _drawStatChip(Canvas canvas, Offset topLeft, IconData icon, String label,
      ColorScheme cs) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(topLeft.dx, topLeft.dy, 76, 30),
        const Radius.circular(8),
      ),
      Paint()..color = cs.surfaceContainerLow,
    );
    _paintIcon(canvas, Offset(topLeft.dx + 12, topLeft.dy + 15), icon,
        const Color(0xFF4ADE80), 13);
    _paintText(canvas, Offset(topLeft.dx + 26, topLeft.dy + 9), label,
        cs.onSurface, 8, FontWeight.w600);
  }

  void _drawBadge(Canvas canvas, Offset center, IconData icon, String label,
      ColorScheme cs, Color color) {
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
    _paintText(canvas, Offset(center.dx - 6, center.dy - 6), label, cs.onSurface,
        8.5, FontWeight.w700);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Painter 2: Map ───────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  final ColorScheme cs;
  _MapPainter(this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Map card
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

    // Grid lines
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

    // Roads
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 90, cy + 20), Offset(cx + 90, cy + 20), roadPaint);
    canvas.drawLine(Offset(cx, cy - 80), Offset(cx, cy + 20), roadPaint);

    // Dashes
    final dashPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 5; i++) {
      final x = cx - 70.0 + i * 34;
      canvas.drawLine(Offset(x, cy + 20), Offset(x + 18, cy + 20), dashPaint);
    }

    // Route dots
    final dotPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(cx - 20, cy + 10), Offset(cx + 58, cy - 42), dotPaint);

    // Destination pin
    _drawPin(canvas, Offset(cx + 60, cy - 48), cs.error);

    // Courier dot
    canvas.drawCircle(
      Offset(cx - 20, cy + 10),
      16,
      Paint()..color = const Color(0xFF4ADE80),
    );
    _paintIcon(canvas, Offset(cx - 20, cy + 10), Icons.directions_bike_rounded,
        Colors.white, 14);

    // Pulse ring
    canvas.drawCircle(
      Offset(cx - 20, cy + 10),
      26,
      Paint()
        ..color = const Color(0xFF4ADE80).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ETA card
    _drawCard(canvas, Offset(cx, cy - 88), 150, 28, 12);
    _paintIcon(canvas, Offset(cx - 58, cy - 88), Icons.access_time_rounded,
        const Color(0xFF4ADE80), 13);
    _paintText(canvas, Offset(cx - 42, cy - 96), 'Доедете через 8 мин',
        cs.onSurface, 8.5, FontWeight.w600);
  }

  void _drawPin(Canvas canvas, Offset c, Color color) {
    canvas.drawCircle(
      c + const Offset(0, 2),
      16,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(c, 16, Paint()..color = color);
    final path = Path()
      ..moveTo(c.dx - 7, c.dy + 14)
      ..lineTo(c.dx + 7, c.dy + 14)
      ..lineTo(c.dx, c.dy + 26)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    _paintIcon(canvas, c, Icons.home_rounded, Colors.white, 14);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Painter 3: Earnings ──────────────────────────────────────────────────────

class _EarningsPainter extends CustomPainter {
  final ColorScheme cs;
  _EarningsPainter(this.cs);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Phone shadow + body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 4, cy + 14), width: 150, height: 230),
        const Radius.circular(28),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 10), width: 150, height: 230),
      const Radius.circular(28),
    );
    canvas.drawRRect(phoneRect, Paint()..color = Colors.white);

    // Header
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 75, cy - 105, 150, 50),
        const Radius.circular(28),
      ),
      Paint()..color = const Color(0xFF4ADE80),
    );
    _paintText(canvas, Offset(cx - 40, cy - 99), 'Мой заработок', Colors.white, 9,
        FontWeight.w700);
    _paintText(canvas, Offset(cx - 44, cy - 86), '14 280 ₽', Colors.white, 16,
        FontWeight.w800);

    // Bar chart
    final barData = [0.4, 0.65, 0.5, 0.8, 0.6, 0.9, 0.75];
    final barW = 14.0;
    final chartLeft = cx - 49.0;
    for (int i = 0; i < barData.length; i++) {
      final x = chartLeft + i * (barW + 2);
      final barH = barData[i] * 60;
      final y = cy - 20 - barH;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, barH),
          const Radius.circular(4),
        ),
        Paint()
          ..color = i == 5
              ? const Color(0xFF4ADE80)
              : const Color(0xFF4ADE80).withValues(alpha: 0.25),
      );
    }

    // Day labels
    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    for (int i = 0; i < days.length; i++) {
      final x = chartLeft + i * (barW + 2);
      _paintText(canvas, Offset(x + 1, cy - 14), days[i], cs.onSurfaceVariant, 7,
          FontWeight.w500);
    }

    // Divider
    canvas.drawLine(
      Offset(cx - 60, cy + 2),
      Offset(cx + 60, cy + 2),
      Paint()
        ..color = cs.outlineVariant
        ..strokeWidth = 1,
    );

    // Stats
    _paintIcon(canvas, Offset(cx - 48, cy + 22), Icons.local_shipping_outlined,
        const Color(0xFF4ADE80), 14);
    _paintText(canvas, Offset(cx - 34, cy + 14), '34 доставки', cs.onSurface, 8,
        FontWeight.w600);
    _paintText(canvas, Offset(cx - 34, cy + 24), 'за неделю', cs.onSurfaceVariant,
        7, FontWeight.w400);

    _paintIcon(canvas, Offset(cx + 10, cy + 22), Icons.star_rounded,
        Colors.amber, 14);
    _paintText(canvas, Offset(cx + 24, cy + 14), 'Рейтинг 4.9', cs.onSurface, 8,
        FontWeight.w600);
    _paintText(canvas, Offset(cx + 24, cy + 24), '48 оценок', cs.onSurfaceVariant,
        7, FontWeight.w400);

    // Payout button
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 56, cy + 62, 112, 26),
        const Radius.circular(13),
      ),
      Paint()..color = const Color(0xFF4ADE80),
    );
    _paintText(canvas, Offset(cx - 32, cy + 68), 'Вывести деньги',
        Colors.white, 8.5, FontWeight.w700);

    // Floating badges
    _drawFloatingBadge(canvas, Offset(cx + 100, cy - 50), '🔥 Рекорд', cs);
    _drawFloatingBadge(canvas, Offset(cx - 100, cy + 30), '⭐ Топ', cs);
  }

  void _drawFloatingBadge(Canvas canvas, Offset center, String text, ColorScheme cs) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontSize: 9, color: cs.onSurface, fontWeight: FontWeight.w700),
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Data ─────────────────────────────────────────────────────────────────────

enum _IllustrationType { schedule, map, earnings }

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
