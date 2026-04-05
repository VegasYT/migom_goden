import 'package:flutter/material.dart';

import '../../../domain/company_model.dart';

class RestaurantInfo extends StatelessWidget {
  final CompanyMenu menu;
  const RestaurantInfo({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  menu.companyName,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),

          if (menu.rating != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFFBBF24),
                  label: '${menu.rating!.toStringAsFixed(1)}${menu.reviewCount != null ? ' (${menu.reviewCount})' : ''}',
                ),
              ],
            ),
          ],

          if (menu.description != null) ...[
            const SizedBox(height: 12),
            Text(
              menu.description!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant, height: 1),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _StatChip({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor ?? colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
