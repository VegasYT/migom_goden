import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/company_model.dart';
import '../providers/cart_provider.dart';
import '../providers/companies_provider.dart';
import '../widgets/restaurant/restaurant_cart_bar.dart';
import 'home_screen.dart';
import '../widgets/restaurant/restaurant_category_bar.dart';
import '../widgets/restaurant/restaurant_cover_app_bar.dart';
import '../widgets/restaurant/restaurant_info.dart';
import '../widgets/restaurant/restaurant_menu_section.dart';
import '../widgets/restaurant/restaurant_reviews_section.dart';

class RestaurantScreen extends ConsumerWidget {
  final int restaurantId;
  const RestaurantScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(companyMenuProvider(restaurantId));
    final colorScheme = Theme.of(context).colorScheme;

    return menuAsync.when(
      loading: () => Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (menu) => _RestaurantContent(
        restaurantId: restaurantId,
        menu: menu,
      ),
    );
  }
}

class _RestaurantContent extends ConsumerStatefulWidget {
  final int restaurantId;
  final CompanyMenu menu;
  const _RestaurantContent({required this.restaurantId, required this.menu});

  @override
  ConsumerState<_RestaurantContent> createState() => _RestaurantContentState();
}

class _RestaurantContentState extends ConsumerState<_RestaurantContent> {
  final _scrollController = ScrollController();
  final _categoryScrollController = ScrollController();
  final List<GlobalKey> _categoryKeys = [];
  int _activeCategoryIndex = 0;
  bool _headerCollapsed = false;

  @override
  void initState() {
    super.initState();
    _categoryKeys.addAll(
      List.generate(widget.menu.categories.length, (_) => GlobalKey()),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final collapsed = _scrollController.offset > 200;
    if (collapsed != _headerCollapsed) {
      setState(() => _headerCollapsed = collapsed);
    }
  }

  void _scrollToCategory(int index) {
    setState(() => _activeCategoryIndex = index);
    final key = _categoryKeys[index];
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
    _categoryScrollController.animateTo(
      index * 100.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _addToCart(int itemId) async {
    HapticFeedback.lightImpact();
    await ref.read(cartProvider.notifier).addItem(catalogItemId: itemId);
  }

  void _removeFromCart(int itemId) async {
    HapticFeedback.lightImpact();
    final cart = ref.read(cartProvider).valueOrNull;
    if (cart == null) return;
    for (final c in cart.carts) {
      for (final item in c.items) {
        if (item.catalogItemId == itemId) {
          if (item.quantity <= 1) {
            await ref.read(cartProvider.notifier).removeItem(item.id);
          } else {
            await ref.read(cartProvider.notifier).updateItem(
              itemId: item.id,
              quantity: item.quantity - 1,
            );
          }
          return;
        }
      }
    }
  }

  Map<int, int> _buildCartMap() {
    final cart = ref.watch(cartProvider).valueOrNull;
    if (cart == null) return {};
    try {
      final companyCart = cart.carts.firstWhere(
        (c) => c.companyId == widget.restaurantId,
      );
      return {for (final item in companyCart.items) item.catalogItemId: item.quantity};
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final menu = widget.menu;
    final cartAsync = ref.watch(cartProvider);
    final cartMap = _buildCartMap();
    final cartCount = cartAsync.valueOrNull?.carts
        .where((c) => c.companyId == widget.restaurantId)
        .fold<int>(0, (sum, c) => sum + c.totalItems) ?? 0;
    final cartTotal = cartAsync.valueOrNull?.carts
        .where((c) => c.companyId == widget.restaurantId)
        .fold<double>(0, (sum, c) => sum + c.total) ?? 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                leading: RestaurantCircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                actions: [
                  RestaurantCircleIconButton(
                    icon: Icons.favorite_border_rounded,
                    onTap: () {},
                  ),
                  RestaurantCircleIconButton(
                    icon: Icons.share_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: RestaurantCoverImage(
                    url: menu.logoUrl ?? '',
                  ),
                ),
                title: AnimatedOpacity(
                  opacity: _headerCollapsed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    menu.companyName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              SliverToBoxAdapter(child: RestaurantInfo(menu: menu)),

              if (menu.categories.isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: RestaurantCategoryBarDelegate(
                    categories: menu.categories,
                    activeIndex: _activeCategoryIndex,
                    scrollController: _categoryScrollController,
                    onCategoryTap: _scrollToCategory,
                  ),
                ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, catIndex) {
                    final category = menu.categories[catIndex];
                    return RestaurantMenuSection(
                      key: _categoryKeys[catIndex],
                      category: category,
                      cart: cartMap,
                      companyId: widget.restaurantId,
                      onAdd: _addToCart,
                      onRemove: _removeFromCart,
                    );
                  },
                  childCount: menu.categories.length,
                ),
              ),

              const SliverToBoxAdapter(
                child: RestaurantReviewsSection(reviews: [], rating: 0),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: cartCount > 0 ? 80 : 24),
              ),
            ],
          ),

          if (cartCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: RestaurantCartBar(
                count: cartCount,
                total: cartTotal,
                onTap: () {
                  ref.read(homeTabOverrideProvider.notifier).state = 1;
                  context.go('/home');
                },
              ),
            ),
        ],
      ),
    );
  }
}
