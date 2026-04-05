enum NotificationType { order, promo, system }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String time;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'system';
    final type = switch (typeStr) {
      'order' => NotificationType.order,
      'promo' => NotificationType.promo,
      _ => NotificationType.system,
    };
    final createdAt = json['created_at'] as String?;
    return NotificationModel(
      id: json['id'].toString(),
      type: type,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      time: createdAt != null ? _formatTime(createdAt) : '',
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  static String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
      if (diff.inHours < 24) return '${diff.inHours} ч назад';
      return '${diff.inDays} д назад';
    } catch (_) {
      return isoString;
    }
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}
