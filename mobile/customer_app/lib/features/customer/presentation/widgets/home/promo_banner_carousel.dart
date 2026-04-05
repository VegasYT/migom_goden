import 'package:flutter/material.dart';

// Static promo data - replace with API /promo-banners when backend returns rich data
const _promos = [
  (
    title: 'Бесплатная\nдоставка',
    subtitle: 'На первые 3 заказа',
    badge: '🎉 Новым',
    gradientColors: [0xFF4ADE80, 0xFF059669],
  ),
  (
    title: 'Скидка 20%\nна обед',
    subtitle: 'С 12:00 до 15:00',
    badge: '🕐 Сегодня',
    gradientColors: [0xFF60A5FA, 0xFF2563EB],
  ),
  (
    title: 'Combo\nвыгоднее',
    subtitle: 'Сэкономь до 300₽',
    badge: '🔥 Хит',
    gradientColors: [0xFFF97316, 0xFFDC2626],
  ),
];

class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({super.key});

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  final _controller = PageController(viewportFraction: 0.88);
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const promos = _promos;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: promos.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _PromoBanner(item: promos[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            promos.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _current ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _current
                    ? colorScheme.primary
                    : colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final ({String title, String subtitle, String badge, List<int> gradientColors}) item;
  const _PromoBanner({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.gradientColors.map((c) => Color(c)).toList(),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Подробнее',
                                style: TextStyle(
                                  color: Color(item.gradientColors[0]),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
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
          ],
        ),
      ),
    );
  }
}
