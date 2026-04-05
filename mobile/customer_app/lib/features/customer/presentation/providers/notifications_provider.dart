import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notifications_service.dart';
import '../../domain/notification_model.dart';

final notificationsServiceProvider =
    Provider<NotificationsService>((ref) => NotificationsService());

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  NotificationsService get _service => ref.read(notificationsServiceProvider);

  @override
  Future<List<NotificationModel>> build() async {
    return _service.getNotifications();
  }

  Future<void> markRead(String id) async {
    await _service.markRead(id);
    final updated = (state.valueOrNull ?? []).map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    state = AsyncData(updated);
  }

  Future<void> markAllRead() async {
    await _service.markAllRead();
    final updated =
        (state.valueOrNull ?? []).map((n) => n.copyWith(isRead: true)).toList();
    state = AsyncData(updated);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
  NotificationsNotifier.new,
);

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});
