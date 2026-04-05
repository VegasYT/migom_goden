import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/profile_model.dart';

// ─── Avatar header ─────────────────────────────────────────────────────────────

class ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onEditTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: 24),
        Stack(
          children: [
            _Avatar(avatarUrl: profile.avatarUrl, name: profile.name),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onEditTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 15,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          profile.name,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          profile.phone,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;

  const _Avatar({this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: 52,
      backgroundColor: colorScheme.primaryContainer,
      child: avatarUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(),
                errorWidget: (_, __, ___) => _initials(context),
              ),
            )
          : _initials(context),
    );
  }

  Widget _initials(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = name.trim().split(' ').take(2).map((w) => w[0]).join();
    return Text(
      initials.toUpperCase(),
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

// ─── Stats row ─────────────────────────────────────────────────────────────────

class ProfileStatsRow extends StatelessWidget {
  final int ordersCount;
  final int bonusPoints;

  const ProfileStatsRow({
    super.key,
    required this.ordersCount,
    required this.bonusPoints,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              icon: Icons.receipt_long_rounded,
              value: '$ordersCount',
              label: 'Заказов',
            ),
          ),
          VerticalDivider(width: 1, color: colorScheme.outlineVariant, thickness: 1),
          Expanded(
            child: _StatCell(
              icon: Icons.stars_rounded,
              value: '$bonusPoints',
              label: 'Мои отзывы',
              iconColor: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: iconColor ?? colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─── Menu tile ─────────────────────────────────────────────────────────────────

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;
  final Widget? trailing;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.iconColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────────

class ProfileSectionLabel extends StatelessWidget {
  final String text;

  const ProfileSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ─── Recent order tile ─────────────────────────────────────────────────────────

class ProfileOrderTile extends StatelessWidget {
  final ProfileOrderItem order;

  const ProfileOrderTile({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (statusLabel, statusColor) = switch (order.status) {
      OrderStatus.delivered => ('Доставлен', colorScheme.primary),
      OrderStatus.cancelled => ('Отменён', colorScheme.error),
      OrderStatus.inProgress => ('В пути', colorScheme.tertiary),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.storefront_rounded, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.restaurantName,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  order.date,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${order.total} ₽',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: textTheme.labelSmall?.copyWith(color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
