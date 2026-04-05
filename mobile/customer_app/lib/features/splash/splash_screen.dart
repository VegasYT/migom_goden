import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/websocket_service.dart';
import '../auth/data/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _textFadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      await _controller.forward();
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      final loggedIn = await AuthService().isLoggedIn();
      if (!mounted) return;
      if (loggedIn) WebSocketService().connect();
      context.go(loggedIn ? '/home' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(size: 280, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _Blob(size: 340, color: Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: _Blob(size: 180, color: Colors.white.withValues(alpha: 0.05)),
          ),
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.delivery_dining_rounded,
                        size: 52,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _textFadeAnim,
                  child: Column(
                    children: [
                      Text(
                        'Migom',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Доставка рядом с вами',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ],
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

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
