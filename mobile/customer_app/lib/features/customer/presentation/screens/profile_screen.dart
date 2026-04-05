import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile/profile_widgets.dart';
import 'address_select_screen.dart';
import 'payment_method_screen.dart';
import 'personal_data_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (profile) => _buildContent(context, ref, profile),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, profile) {
    final colorScheme = Theme.of(context).colorScheme;
    final orders = ref.watch(profileOrdersProvider);

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
                // Avatar + name
                ProfileHeader(
                  profile: profile,
                  onEditTap: () {},
                ),

                // Stats
                ProfileStatsRow(
                  ordersCount: profile.ordersCount,
                  bonusPoints: profile.bonusPoints,
                ),

                // Account section
                const ProfileSectionLabel('Аккаунт'),
                _MenuCard(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Личные данные',
                      subtitle: profile.name,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PersonalDataScreen(),
                        ),
                      ),
                    ),
                    _Divider(),
                    ProfileMenuTile(
                      icon: Icons.location_on_outlined,
                      label: 'Адреса доставки',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AddressSelectScreen(),
                        ),
                      ),
                    ),
                    _Divider(),
                    ProfileMenuTile(
                      icon: Icons.payment_outlined,
                      label: 'Способы оплаты',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PaymentMethodScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                // Orders section
                const ProfileSectionLabel('Последние заказы'),
                ...List.generate(
                  orders.length,
                  (i) => Padding(
                    padding: EdgeInsets.only(bottom: i < orders.length - 1 ? 10 : 0),
                    child: ProfileOrderTile(order: orders[i]),
                  ),
                ),

                // Support section
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/login');
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
