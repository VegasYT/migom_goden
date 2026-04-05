import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/catalog_item_detail_model.dart';

// ─── Photo hero ────────────────────────────────────────────────────────────────

class ItemDetailPhoto extends StatelessWidget {
  final String? photoUrl;
  final String itemName;

  const ItemDetailPhoto({super.key, this.photoUrl, required this.itemName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: photoUrl != null
          ? CachedNetworkImage(
              imageUrl: photoUrl!,
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(colorScheme),
              errorWidget: (_, __, ___) => _placeholder(colorScheme),
            )
          : _placeholder(colorScheme),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return Container(
      height: 260,
      color: colorScheme.primaryContainer,
      child: Icon(
        Icons.fastfood_rounded,
        size: 72,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

// ─── Discount badge ────────────────────────────────────────────────────────────

class ItemDetailDiscountBadge extends StatelessWidget {
  final CatalogItemDetailDiscount discount;

  const ItemDetailDiscountBadge({super.key, required this.discount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        discount.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Price row ─────────────────────────────────────────────────────────────────

class ItemDetailPriceRow extends StatelessWidget {
  final double price;
  final double finalPrice;
  final bool hasDiscount;

  const ItemDetailPriceRow({
    super.key,
    required this.price,
    required this.finalPrice,
    required this.hasDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${finalPrice.toStringAsFixed(0)}₽',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '${price.toStringAsFixed(0)}₽',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
                decorationColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Rating summary ────────────────────────────────────────────────────────────

class ItemDetailRatingRow extends StatelessWidget {
  final double averageRating;
  final int reviewCount;

  const ItemDetailRatingRow({
    super.key,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (reviewCount == 0) return const SizedBox.shrink();

    return Row(
      children: [
        ...List.generate(
          5,
          (i) => Icon(
            i < averageRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: const Color(0xFFFBBF24),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          averageRating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviewCount отзыв${_reviewSuffix(reviewCount)})',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _reviewSuffix(int n) {
    if (n % 100 >= 11 && n % 100 <= 14) return 'ов';
    return switch (n % 10) {
      1 => '',
      2 || 3 || 4 => 'а',
      _ => 'ов',
    };
  }
}

// ─── Quantity stepper ──────────────────────────────────────────────────────────

class ItemDetailQuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const ItemDetailQuantityStepper({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: onRemove,
            enabled: quantity > 1,
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: onAdd, enabled: true),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepButton({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

// ─── Add to cart button ────────────────────────────────────────────────────────

class ItemDetailAddToCartButton extends StatelessWidget {
  final double totalPrice;
  final VoidCallback onTap;

  const ItemDetailAddToCartButton({
    super.key,
    required this.totalPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              'В корзину  •  ${totalPrice.toStringAsFixed(0)}₽',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review card ───────────────────────────────────────────────────────────────

class ItemDetailReviewCard extends StatelessWidget {
  final CatalogItemReview review;

  const ItemDetailReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  review.customerName[0],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: i < review.rating
                              ? const Color(0xFFFBBF24)
                              : colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
