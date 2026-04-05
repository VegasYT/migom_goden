import 'package:flutter/material.dart';

class CartEmpty extends StatelessWidget {
  const CartEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text('Корзина', style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: colorScheme.outlineVariant),
          ),
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🛒', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Корзина пуста',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте блюда из меню ресторана',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.storefront_rounded),
                  label: const Text('Перейти к ресторанам'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
