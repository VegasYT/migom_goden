import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notifications_provider.dart';
import '../widgets/notifications/notification_tile.dart';
import '../widgets/notifications/notifications_empty.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final notifications = notificationsAsync.valueOrNull ?? [];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              const Text('Уведомления'),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unread',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (unread > 0)
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllRead(),
                child: const Text('Прочитать все'),
              ),
          ],
        ),

        if (notificationsAsync.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (notifications.isEmpty)
          const SliverFillRemaining(child: NotificationsEmpty())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index.isOdd) {
                  return Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                    indent: 70,
                  );
                }
                final n = notifications[index ~/ 2];
                return NotificationTile(
                  notification: n,
                  onTap: () =>
                      ref.read(notificationsProvider.notifier).markRead(n.id),
                );
              },
              childCount: notifications.length * 2 - 1,
            ),
          ),
      ],
    );
  }
}
