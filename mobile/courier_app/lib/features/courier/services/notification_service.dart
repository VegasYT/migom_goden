import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification IDs
const _kIncomingOrderId = 1;
const _kActiveDeliveryId = 2;

/// Android action IDs
const _kActionAccept    = 'order_accept';
const _kActionDecline   = 'order_decline';
const _kActionPickedUp  = 'order_picked_up';
const _kActionDelivered = 'order_delivered';

/// MethodChannel that mirrors the native BroadcastReceiver
const _kChannel = MethodChannel('com.migom.courier_app/notifications');

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static VoidCallback? _onAccept;
  static VoidCallback? _onDecline;
  static VoidCallback? _onPickedUp;
  static VoidCallback? _onDelivered;

  // ── Init ─────────────────────────────────────────────────────────────────────

  static Future<void> init({
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    required VoidCallback onPickedUp,
    required VoidCallback onDelivered,
  }) async {
    _onAccept    = onAccept;
    _onDecline   = onDecline;
    _onPickedUp  = onPickedUp;
    _onDelivered = onDelivered;

    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _kChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'orderAccept':    _onAccept?.call();
        case 'orderDecline':   _onDecline?.call();
        case 'orderPickedUp':  _onPickedUp?.call();
        case 'orderDelivered': _onDelivered?.call();
      }
    });
  }

  // ── Incoming order notification ───────────────────────────────────────────────

  static Future<void> showIncomingOrder({
    required String orderId,
    required String restaurantName,
    required String address,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'incoming_order',
      'Новые заказы',
      channelDescription: 'Уведомления о входящих заказах',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      playSound: false,
      enableVibration: true,
      actions: [
        const AndroidNotificationAction(
          _kActionAccept,
          'Принять',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          _kActionDecline,
          'Отклонить',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.show(
      _kIncomingOrderId,
      'Новый заказ',
      '$restaurantName  ·  $address',
      NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> cancelIncomingOrder() async {
    await _plugin.cancel(_kIncomingOrderId);
  }

  // ── Active delivery notification ──────────────────────────────────────────────

  /// [destinationAddress] - ресторан на этапе toRestaurant, клиент на toCustomer
  /// [showPickedUpAction] - кнопка «Забрал» только на этапе toRestaurant
  /// [showDeliveredAction] - кнопка «Доставил» только на этапе toCustomer
  static Future<void> showActiveDelivery({
    required String destinationAddress,
    required String stage,
    required int estimatedMinutes,
    bool showPickedUpAction = false,
    bool showDeliveredAction = false,
  }) async {
    // Countdown: now + estimatedMinutes, Android ticks down automatically.
    // estimatedMinutes == 0 means "awaiting confirmation" - no timer shown.
    final showTimer = estimatedMinutes > 0;
    final whenMs = DateTime.now().millisecondsSinceEpoch
        + estimatedMinutes * 60 * 1000;

    final actions = [
      if (showPickedUpAction)
        const AndroidNotificationAction(
          _kActionPickedUp,
          'Забрал заказ',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      if (showDeliveredAction)
        const AndroidNotificationAction(
          _kActionDelivered,
          'Доставил',
          showsUserInterface: true,
          cancelNotification: false,
        ),
    ];

    final androidDetails = AndroidNotificationDetails(
      'active_delivery',
      'Активная доставка',
      channelDescription: 'Отображается пока доставка не подтверждена клиентом',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      visibility: NotificationVisibility.public,
      when: showTimer ? whenMs : null,
      usesChronometer: showTimer,
      chronometerCountDown: showTimer,
      subText: stage,
      actions: actions,
    );

    String? body;
    if (showTimer) {
      final arrival = DateTime.now().add(Duration(minutes: estimatedMinutes));
      final h = arrival.hour.toString().padLeft(2, '0');
      final m = arrival.minute.toString().padLeft(2, '0');
      body = 'Прибытие в $h:$m';
    }

    await _plugin.show(
      _kActiveDeliveryId,
      destinationAddress,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> cancelActiveDelivery() async {
    await _plugin.cancel(_kActiveDeliveryId);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────────

  static void _onNotificationResponse(NotificationResponse response) {
    switch (response.actionId) {
      case _kActionAccept:    _onAccept?.call();
      case _kActionDecline:   _onDecline?.call();
      case _kActionPickedUp:  _onPickedUp?.call();
      case _kActionDelivered: _onDelivered?.call();
    }
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  // Handled natively; app brought to foreground, MethodChannel picks up on resume.
}
