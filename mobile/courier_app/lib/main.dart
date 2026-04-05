import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/courier/presentation/providers/active_order_provider.dart';
import 'features/courier/presentation/providers/incoming_order_provider.dart';
import 'features/courier/presentation/providers/location_provider.dart';
import 'features/courier/presentation/providers/ws_provider.dart';
import 'features/courier/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    NotificationService.init(
      onAccept:    () => ref.read(incomingOrderProvider.notifier).accept(),
      onDecline:   () => ref.read(incomingOrderProvider.notifier).decline(),
      onPickedUp:  () => ref.read(activeOrderProvider.notifier).pickedUp(),
      onDelivered: () => ref.read(activeOrderProvider.notifier).delivered(),
    );
  }

  bool _wsConnected = false;

  void _connectWsIfNeeded() {
    if (_wsConnected) return;
    _wsConnected = true;
    // Start GPS tracking & location reporting to server
    ref.read(locationProvider);
    // Connect WebSocket for real-time order offers
    ref.read(wsInitProvider);
    // Restore active order if app restarted mid-delivery
    ref.read(activeOrderProvider.notifier).loadFromApi();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Connect WS only after authenticated
    ref.listen<AuthStatus>(authProvider, (prev, next) {
      if (next == AuthStatus.authenticated) {
        _connectWsIfNeeded();
      }
    });
    // Also connect if already authenticated on build
    if (ref.read(authProvider) == AuthStatus.authenticated) {
      _connectWsIfNeeded();
    }

    // Global listener: when order is accepted (from notification OR in-app),
    // fetch full order data and navigate to the order screen.
    ref.listen<IncomingOrderState>(incomingOrderProvider, (prev, next) async {
      if (prev?.status != IncomingOrderStatus.accepted &&
          next.status == IncomingOrderStatus.accepted) {
        // Small delay so the bottom sheet (if open) finishes closing first
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        // Load actual order data from API
        await ref.read(activeOrderProvider.notifier).loadFromApi();
        if (mounted) router.go('/active-order');
      }
    });

    return MaterialApp.router(
      title: 'Migom Courier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
