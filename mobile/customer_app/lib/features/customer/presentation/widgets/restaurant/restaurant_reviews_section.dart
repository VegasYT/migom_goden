import 'package:flutter/material.dart';

import '../../../domain/catalog_item_detail_model.dart';

class RestaurantReviewsSection extends StatelessWidget {
  final List<CatalogItemReview> reviews;
  final double rating;

  const RestaurantReviewsSection({
    super.key,
    required this.reviews,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Отзывы',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFFBBF24)),
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RestaurantReviewCard(review: review),
            ),
          ),
        ],
      ),
    );
  }
}

class RestaurantReviewCard extends StatelessWidget {
  final CatalogItemReview review;
  const RestaurantReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  review.customerName.isNotEmpty ? review.customerName[0] : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 14,
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
                      style: textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 12,
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
                '${review.createdAt.day}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.year}',
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
}
