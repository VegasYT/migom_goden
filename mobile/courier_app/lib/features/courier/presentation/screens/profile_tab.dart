import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/courier_profile_provider.dart';
import '../widgets/profile/profile_widgets.dart';
import 'vehicle_type_sheet.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(courierProfileSyncProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Профиль'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CourierProfileHeader(
                  profile: profile,
                  onEditTap: () => context.push('/profile/personal-data'),
                ),

                CourierStatsRow(
                  totalDistanceKm: profile.totalDistanceKm,
                  totalDeliveries: profile.totalDeliveries,
                ),

                const ProfileSectionLabel('Аккаунт'),
                _MenuCard(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Личные данные',
                      subtitle: profile.name,
                      onTap: () => context.push('/profile/personal-data'),
                    ),
                    _Divider(),
                    ProfileMenuTile(
                      icon: Icons.directions_bike_rounded,
                      label: 'Транспортное средство',
                      subtitle: profile.vehicleType.label,
                      onTap: () => VehicleTypeSheet.show(context),
                    ),
                  ],
                ),

                const ProfileSectionLabel('Прочее'),
                _MenuCard(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.support_agent_outlined,
                      label: 'Поддержка',
                      onTap: () {},
                    ),
                    _Divider(),
                    ProfileMenuTile(
                      icon: Icons.info_outline_rounded,
                      label: 'О приложении',
                      subtitle: 'Версия 1.0.0',
                      onTap: () {},
                    ),
                    _Divider(),
                    ProfileMenuTile(
                      icon: Icons.logout_rounded,
                      label: 'Выйти',
                      iconColor: colorScheme.error,
                      onTap: () => _confirmLogout(context, ref),
                      trailing: const SizedBox.shrink(),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вам потребуется войти снова.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout().then((_) {
                if (context.mounted) context.go('/login');
              });
            },
            child: Text(
              'Выйти',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final List<Widget> children;

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
      indent: 54,
    );
  }
}
