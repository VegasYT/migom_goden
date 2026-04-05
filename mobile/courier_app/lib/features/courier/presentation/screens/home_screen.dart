import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_tab.dart';
import 'order_history_tab.dart';
import 'profile_tab.dart';
import 'stats_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Главная',
    ),
    _TabItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Заказы',
    ),
    _TabItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Статистика',
    ),
    _TabItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Профиль',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness:
            colorScheme.brightness == Brightness.light
                ? Brightness.dark
                : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const HomeTab(),
            const OrderHistoryTab(),
            const StatsTab(),
            const ProfileTab(),
          ],
        ),
        bottomNavigationBar: _AppBottomBar(
          currentIndex: _currentIndex,
          tabs: _tabs,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─── Bottom navigation bar ────────────────────────────────────────────────────

class _AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  const _AppBottomBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == currentIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: isActive ? 48 : 40,
                        height: isActive ? 32 : 28,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          size: isActive ? 22 : 20,
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: (textTheme.labelSmall ?? const TextStyle())
                            .copyWith(
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: isActive ? 11 : 10,
                        ),
                        child: Text(tab.label),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

