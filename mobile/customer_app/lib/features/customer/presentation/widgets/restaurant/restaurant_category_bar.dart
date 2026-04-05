import 'package:flutter/material.dart';

import '../../../domain/company_model.dart';

class RestaurantCategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final List<MenuCategory> categories;
  final int activeIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onCategoryTap;

  const RestaurantCategoryBarDelegate({
    required this.categories,
    required this.activeIndex,
    required this.scrollController,
    required this.onCategoryTap,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isActive = i == activeIndex;
                return GestureDetector(
                  onTap: () => onCategoryTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        categories[i].name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(color: colorScheme.outlineVariant, height: 1),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(RestaurantCategoryBarDelegate old) =>
      old.activeIndex != activeIndex;
}
