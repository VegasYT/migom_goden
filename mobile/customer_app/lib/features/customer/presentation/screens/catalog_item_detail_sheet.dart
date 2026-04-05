import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/catalog_item_detail_provider.dart';
import '../widgets/catalog_item/catalog_item_detail_widgets.dart';

/// Показывает карточку товара как modal bottom sheet.
/// Вызывать через [CatalogItemDetailSheet.show].
class CatalogItemDetailSheet extends ConsumerStatefulWidget {
  final int itemId;
  final int companyId;

  const CatalogItemDetailSheet({
    super.key,
    required this.itemId,
    required this.companyId,
  });

  static Future<void> showByCompany(
      BuildContext context, int companyId, int itemId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CatalogItemDetailSheet(itemId: itemId, companyId: companyId),
    );
  }

  @override
  ConsumerState<CatalogItemDetailSheet> createState() =>
      _CatalogItemDetailSheetState();
}

class _CatalogItemDetailSheetState extends ConsumerState<CatalogItemDetailSheet> {
  int _quantity = 1;

  void _increment() {
    setState(() => _quantity++);
    HapticFeedback.selectionClick();
  }

  void _decrement() {
    if (_quantity <= 1) return;
    setState(() => _quantity--);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(catalogItemDetailByCompanyProvider(
      (companyId: widget.companyId, itemId: widget.itemId),
    ));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (itemAsync is AsyncLoading) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final item = itemAsync.valueOrNull;
    if (item == null) {
      return _NotFoundSheet(bottomPadding: bottomPadding);
    }

    final totalPrice = item.finalPrice * _quantity;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ─── Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ─── Scrollable content
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // Photo + close button
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          ItemDetailPhoto(
                            photoUrl: item.photoUrl,
                            itemName: item.name,
                          ),
                          // Close button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          // Discount badge
                          if (item.hasDiscount)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: ItemDetailDiscountBadge(
                                discount: item.discount!,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Main info
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name + rating
                            Text(
                              item.name,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (item.reviews.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              ItemDetailRatingRow(
                                averageRating: item.averageRating,
                                reviewCount: item.reviews.length,
                              ),
                            ],

                            // Description
                            if (item.description != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                item.description!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.55,
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),
                            Divider(color: colorScheme.outlineVariant, height: 1),
                            const SizedBox(height: 20),

                            // Price + quantity stepper
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ItemDetailPriceRow(
                                    price: item.price,
                                    finalPrice: item.finalPrice,
                                    hasDiscount: item.hasDiscount,
                                  ),
                                ),
                                ItemDetailQuantityStepper(
                                  quantity: _quantity,
                                  onAdd: _increment,
                                  onRemove: _decrement,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Reviews
                    if (item.reviews.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Row(
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
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
                                      item.averageRating.toStringAsFixed(1),
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
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              i < item.reviews.length - 1 ? 10 : 0,
                            ),
                            child: ItemDetailReviewCard(review: item.reviews[i]),
                          ),
                          childCount: item.reviews.length,
                        ),
                      ),
                    ],

                    SliverToBoxAdapter(
                      child: SizedBox(height: bottomPadding + 100),
                    ),
                  ],
                ),
              ),

              // ─── Sticky bottom bar
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
                  ),
                ),
                child: ItemDetailAddToCartButton(
                  totalPrice: totalPrice,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(cartProvider.notifier).addItem(
                      catalogItemId: widget.itemId,
                      quantity: _quantity,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Not found fallback ────────────────────────────────────────────────────────

class _NotFoundSheet extends StatelessWidget {
  final double bottomPadding;
  const _NotFoundSheet({required this.bottomPadding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Товар не найден',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
