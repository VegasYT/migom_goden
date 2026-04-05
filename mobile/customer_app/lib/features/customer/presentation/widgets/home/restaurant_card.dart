import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/home_mock_data.dart';
import '../../../domain/company_model.dart';

// ─── API-based card ────────────────────────────────────────────────────────────

class CompanyCard extends StatelessWidget {
  final CompanyModel company;
  const CompanyCard({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/restaurant/${company.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: company.logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: company.logoUrl!,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(colorScheme, company.name),
                    )
                  : _placeholder(colorScheme, company.name),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (company.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      company.description!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme colorScheme, String name) {
    return Container(
      height: 140,
      color: colorScheme.primaryContainer,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class CompanyCardCompact extends StatelessWidget {
  final CompanyModel company;
  const CompanyCardCompact({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/restaurant/${company.id}'),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: company.logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: company.logoUrl!,
                      width: double.infinity,
                      height: 110,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        height: 110,
                        color: colorScheme.primaryContainer,
                        child: Center(
                          child: Text(
                            company.name.isNotEmpty ? company.name[0] : '?',
                            style: const TextStyle(fontSize: 44),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 110,
                      color: colorScheme.primaryContainer,
                      child: Center(
                        child: Text(
                          company.name.isNotEmpty ? company.name[0] : '?',
                          style: const TextStyle(fontSize: 44),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Text(
                company.name,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legacy mock-based cards (kept for UI compatibility) ──────────────────────

class RestaurantCard extends StatelessWidget {
  final RestaurantItem item;
  const RestaurantCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/restaurant/1'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: colorScheme.primaryContainer,
                      child: Center(
                        child: Text(item.emoji, style: const TextStyle(fontSize: 64)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      if (item.isNew)
                        _RestaurantBadge(label: '🆕 Новый', color: colorScheme.tertiary),
                      if (item.isNew && item.isPromo) const SizedBox(width: 6),
                      if (item.isPromo && item.promoLabel != null)
                        _RestaurantBadge(
                            label: '🔥 ${item.promoLabel}', color: colorScheme.error),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.favorite_border_rounded,
                        size: 18, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      _RatingBadge(rating: item.rating),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.cuisine,
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.access_time_rounded,
                        label: '${item.deliveryTime} мин',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.delivery_dining_rounded,
                        label: item.deliveryPrice,
                        isGreen: item.deliveryPrice == 'Бесплатно',
                      ),
                      const Spacer(),
                      Text(
                        '${item.reviewCount} отзывов',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantCardCompact extends StatelessWidget {
  final RestaurantItem item;
  const RestaurantCardCompact({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/restaurant/1'),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    item.imageUrl,
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      color: colorScheme.primaryContainer,
                      child: Center(
                        child: Text(item.emoji, style: const TextStyle(fontSize: 44)),
                      ),
                    ),
                  ),
                ),
                if (item.isNew || item.isPromo)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: item.isNew
                        ? _RestaurantBadge(label: 'Новый', color: colorScheme.tertiary)
                        : _RestaurantBadge(
                            label: item.promoLabel ?? '', color: colorScheme.error),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.cuisine.split('·').first.trim(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 12, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 3),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.access_time_rounded,
                          size: 12, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        '${item.deliveryTime}м',
                        style: TextStyle(
                            fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared small widgets ──────────────────────────────────────────────────────

class _RestaurantBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _RestaurantBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFBBF24)),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isGreen;
  const _InfoChip({required this.icon, required this.label, this.isGreen = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isGreen ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: isGreen ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
