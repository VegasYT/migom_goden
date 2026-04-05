import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CartRecommendedSection extends StatelessWidget {
  final String restaurantId;

  const CartRecommendedSection({super.key, required this.restaurantId});

  static const _allRecs = {
    'dodici': [
      {
        'emoji': '🥤',
        'name': 'Лимонад',
        'price': '150₽',
        'imageUrl': 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=200&q=80',
      },
      {
        'emoji': '🧀',
        'name': 'Сырные шарики',
        'price': '220₽',
        'imageUrl': 'https://images.unsplash.com/photo-1634487359989-3e90c9432133?w=200&q=80',
      },
      {
        'emoji': '🍫',
        'name': 'Тирамису',
        'price': '280₽',
        'imageUrl': 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=200&q=80',
      },
    ],
    'sushi': [
      {
        'emoji': '🥗',
        'name': 'Цезарь',
        'price': '320₽',
        'imageUrl': 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=200&q=80',
      },
      {
        'emoji': '🥤',
        'name': 'Мисо-суп',
        'price': '120₽',
        'imageUrl': 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=200&q=80',
      },
      {
        'emoji': '🍡',
        'name': 'Моти',
        'price': '180₽',
        'imageUrl': 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=200&q=80',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final recs = _allRecs[restaurantId] ?? _allRecs['dodici']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              const Text('⚡ ', style: TextStyle(fontSize: 15)),
              Text(
                'Добавьте к заказу',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        ...recs.map(
          (rec) => GestureDetector(
            onTap: () => HapticFeedback.selectionClick(),
            child: Container(
              height: 72,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                    child: Image.network(
                      rec['imageUrl']!,
                      width: 80,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 72,
                        color: colorScheme.primaryContainer,
                        child: Center(
                          child: Text(rec['emoji']!, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rec['name']!,
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec['price']!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.add_rounded, size: 18, color: colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
