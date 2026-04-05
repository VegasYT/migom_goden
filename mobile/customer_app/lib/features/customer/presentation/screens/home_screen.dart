import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/websocket_provider.dart';
import '../../data/orders_service.dart';
import '../providers/orders_provider.dart';
import 'cart_screen.dart';
import 'home_tab.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

/// Провайдер для переключения таба извне (например, из RestaurantScreen).
/// Записываем нужный индекс, HomeScreen его считывает и сбрасывает.
final homeTabOverrideProvider = StateProvider<int?>((_) => null);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _confirmationShown = false;

  static const _tabs = [
    _TabItem(icon: Icons.storefront_outlined,    activeIcon: Icons.storefront_rounded,   label: 'Главная'),
    _TabItem(icon: Icons.shopping_bag_outlined,  activeIcon: Icons.shopping_bag_rounded, label: 'Корзина'),
    _TabItem(icon: Icons.receipt_long_outlined,  activeIcon: Icons.receipt_long_rounded, label: 'Заказы'),
    _TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,       label: 'Профиль'),
  ];

  @override
  void initState() {
    super.initState();
    // Слушаем запросы на переключение таба извне
    ref.listenManual(homeTabOverrideProvider, (_, next) {
      if (next != null) {
        setState(() => _currentIndex = next);
        ref.read(homeTabOverrideProvider.notifier).state = null;
      }
    });
    // Слушаем изменения статуса заказов
    ref.listenManual(orderStatusEventProvider, (_, next) {
      print('[HomeScreen] orderStatusEvent: $next');
      next.whenData((event) {
        final status = event.payload['status'] as String?;
        final orderId = event.payload['order_id'] as int?;
        print('[HomeScreen] order $orderId status: $status');
        if (status == 'delivered' && orderId != null && !_confirmationShown) {
          _showDeliveryConfirmation(orderId);
        }
      });
    });
  }

  void _showDeliveryConfirmation(int orderId) {
    _confirmationShown = true;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DeliveryConfirmSheet(
        orderId: orderId,
        onConfirmed: () {
          Navigator.of(ctx).pop();
          _confirmationShown = false;
          ref.invalidate(ordersProvider);
        },
      ),
    ).whenComplete(() => _confirmationShown = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness:
            colorScheme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeTab(),
            CartScreen(),
            OrdersScreen(),
            ProfileScreen(),
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

// ─── Bottom bar ────────────────────────────────────────────────────────────────

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
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.8)),
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
                        style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
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
  const _TabItem({required this.icon, required this.activeIcon, required this.label});
}

// ─── Экран подтверждения получения ────────────────────────────────────────────

class _DeliveryConfirmSheet extends StatefulWidget {
  final int orderId;
  final VoidCallback onConfirmed;

  const _DeliveryConfirmSheet({required this.orderId, required this.onConfirmed});

  @override
  State<_DeliveryConfirmSheet> createState() => _DeliveryConfirmSheetState();
}

class _DeliveryConfirmSheetState extends State<_DeliveryConfirmSheet> {
  bool _loading = false;

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await OrdersService().confirmDelivery(widget.orderId);
      widget.onConfirmed();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delivery_dining_rounded, size: 36, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 16),
          Text(
            'Курьер доставил заказ',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Подтвердите получение заказа №${widget.orderId}',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _confirm,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Подтвердить получение', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
