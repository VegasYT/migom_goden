import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/company_model.dart';
import '../providers/companies_provider.dart';
import '../providers/notifications_provider.dart';
import '../widgets/home/category_chips.dart';
import '../widgets/home/home_app_bar_widgets.dart';
import '../widgets/home/promo_banner_carousel.dart';
import '../widgets/home/restaurant_card.dart';
import '../widgets/home/section_header.dart';
import 'notifications_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final unread = ref.watch(unreadCountProvider);
    final companiesAsync = ref.watch(companiesProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 16,
          title: const DeliveryAddressBar(),
          actions: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => _openNotifications(context),
                ),
                if (unread > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: colorScheme.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: HomeSearchBar(),
              ),
              const PromoBannerCarousel(),
              const SizedBox(height: 20),
              const CategoryChips(),
              const SizedBox(height: 24),
              SectionHeader(
                title: '🍽️ Все заведения',
                actionLabel: 'Все',
                onAction: () {},
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        companiesAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ErrorCard(
                message: e.toString(),
                onRetry: () => ref.invalidate(companiesProvider),
              ),
            ),
          ),
          data: (companies) => _CompaniesSliver(companies: companies),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: NotificationsScreen()),
      ),
    );
  }
}

class _CompaniesSliver extends StatelessWidget {
  final List<CompanyModel> companies;
  const _CompaniesSliver({required this.companies});

  @override
  Widget build(BuildContext context) {
    if (companies.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Заведений пока нет')),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => Padding(
          padding: EdgeInsets.only(
            bottom: i < companies.length - 1 ? 12 : 0,
          ),
          child: CompanyCard(company: companies[i]),
        ),
        childCount: companies.length,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(message,
              style: TextStyle(color: colorScheme.onErrorContainer)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
