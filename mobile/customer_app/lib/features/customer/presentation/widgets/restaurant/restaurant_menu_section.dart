import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/company_model.dart';
import '../../screens/catalog_item_detail_sheet.dart';

class RestaurantMenuSection extends StatelessWidget {
  final MenuCategory category;
  final Map<int, int> cart;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onRemove;
  final int companyId;

  const RestaurantMenuSection({
    super.key,
    required this.category,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.name,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...category.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RestaurantMenuItemCard(
                item: item,
                companyId: companyId,
                quantity: cart[item.id] ?? 0,
                onAdd: () => onAdd(item.id),
                onRemove: () => onRemove(item.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RestaurantMenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int companyId;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const RestaurantMenuItemCard({
    super.key,
    required this.item,
    required this.companyId,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => CatalogItemDetailSheet.showByCompany(context, companyId, item.id),
      child: _CardContent(
        item: item,
        quantity: quantity,
        onAdd: onAdd,
        onRemove: onRemove,
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CardContent({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 110,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: item.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const _PhotoPlaceholder(),
                    )
                  : const _PhotoPlaceholder(),
            ),
          ),
          if (item.hasDiscount && item.discount != null)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.discount!.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(122, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.finalPrice.toStringAsFixed(0)}₽',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (item.hasDiscount)
                          Text(
                            '${item.price.toStringAsFixed(0)}₽',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    quantity == 0
                        ? _AddButton(onTap: onAdd)
                        : _QuantityControl(
                            quantity: quantity,
                            onAdd: onAdd,
                            onRemove: onRemove,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.fastfood_rounded,
          size: 36,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.add_rounded, color: colorScheme.onPrimary, size: 20),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityControl({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.remove_rounded, size: 18, color: colorScheme.primary),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(Icons.add_rounded, size: 18, color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
