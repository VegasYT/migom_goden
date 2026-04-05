import 'package:flutter/material.dart';

import '../../../domain/courier_profile_model.dart';
import 'profile_avatar.dart';

// ─── Avatar header ─────────────────────────────────────────────────────────────

class CourierProfileHeader extends StatelessWidget {
  final CourierProfileModel profile;
  final VoidCallback onEditTap;

  const CourierProfileHeader({
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
        GestureDetector(
          onTap: onEditTap,
          child: ProfileAvatar(avatarUrl: profile.avatarUrl, name: profile.name),
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

// ─── Stats row ─────────────────────────────────────────────────────────────────

class CourierStatsRow extends StatelessWidget {
  final double totalDistanceKm;
  final int totalDeliveries;

  const CourierStatsRow({
    super.key,
    required this.totalDistanceKm,
    required this.totalDeliveries,
  });

  String _formatDistance(double km) {
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(1)} тыс.';
    }
    return '${km.toStringAsFixed(1)} км';
  }

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
              icon: Icons.route_rounded,
              value: _formatDistance(totalDistanceKm),
              label: 'Пройдено',
              iconColor: const Color(0xFF10B981),
            ),
          ),
          VerticalDivider(
            width: 1,
            color: colorScheme.outlineVariant,
            thickness: 1,
          ),
          Expanded(
            child: _StatCell(
              icon: Icons.directions_bike_rounded,
              value: '$totalDeliveries',
              label: 'Доставок',
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
