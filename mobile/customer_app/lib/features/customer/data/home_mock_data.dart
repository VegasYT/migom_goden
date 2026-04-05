// Mock data - будет заменено на реальный API

class CategoryItem {
  final String emoji;
  final String label;
  const CategoryItem({required this.emoji, required this.label});
}

class PromoItem {
  final String title;
  final String subtitle;
  final String badge;
  final List<int> gradientColors;
  const PromoItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.gradientColors,
  });
}

class RestaurantItem {
  final String name;
  final String cuisine;
  final String deliveryTime;
  final String deliveryPrice;
  final double rating;
  final int reviewCount;
  final String emoji;
  final String imageUrl;
  final bool isNew;
  final bool isPromo;
  final String? promoLabel;
  const RestaurantItem({
    required this.name,
    required this.cuisine,
    required this.deliveryTime,
    required this.deliveryPrice,
    required this.rating,
    required this.reviewCount,
    required this.emoji,
    required this.imageUrl,
    this.isNew = false,
    this.isPromo = false,
    this.promoLabel,
  });
}

abstract final class HomeMockData {
  static const categories = [
    CategoryItem(emoji: '🍕', label: 'Пицца'),
    CategoryItem(emoji: '🍣', label: 'Суши'),
    CategoryItem(emoji: '🍔', label: 'Бургеры'),
    CategoryItem(emoji: '🥗', label: 'Салаты'),
    CategoryItem(emoji: '🍜', label: 'Лапша'),
    CategoryItem(emoji: '🌮', label: 'Тако'),
    CategoryItem(emoji: '☕', label: 'Кофе'),
    CategoryItem(emoji: '🧁', label: 'Десерты'),
  ];

  static const promos = [
    PromoItem(
      title: 'Бесплатная\nдоставка',
      subtitle: 'На первые 3 заказа',
      badge: '🎉 Новым',
      gradientColors: [0xFF4ADE80, 0xFF059669],
    ),
    PromoItem(
      title: 'Скидка 20%\nна обед',
      subtitle: 'С 12:00 до 15:00',
      badge: '🕐 Сегодня',
      gradientColors: [0xFF60A5FA, 0xFF2563EB],
    ),
    PromoItem(
      title: 'Combo\nвыгоднее',
      subtitle: 'Сэкономь до 300₽',
      badge: '🔥 Хит',
      gradientColors: [0xFFF97316, 0xFFDC2626],
    ),
  ];

  static const popular = [
    RestaurantItem(
      name: 'Dodici Pizza',
      cuisine: 'Пицца · Паста · Десерты',
      deliveryTime: '25–35',
      deliveryPrice: 'Бесплатно',
      rating: 4.9,
      reviewCount: 1240,
      emoji: '🍕',
      imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80',
      isPromo: true,
      promoLabel: '-15%',
    ),
    RestaurantItem(
      name: 'Sushi Master',
      cuisine: 'Суши · Роллы · Сашими',
      deliveryTime: '30–45',
      deliveryPrice: '49₽',
      rating: 4.8,
      reviewCount: 876,
      emoji: '🍣',
      imageUrl: 'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=600&q=80',
      isNew: true,
    ),
    RestaurantItem(
      name: 'Burger Bros',
      cuisine: 'Бургеры · Картофель · Напитки',
      deliveryTime: '20–30',
      deliveryPrice: 'Бесплатно',
      rating: 4.7,
      reviewCount: 2103,
      emoji: '🍔',
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80',
      isPromo: true,
      promoLabel: 'Combo',
    ),
    RestaurantItem(
      name: 'Green Bowl',
      cuisine: 'Здоровое · Салаты · Смузи',
      deliveryTime: '15–25',
      deliveryPrice: '29₽',
      rating: 4.6,
      reviewCount: 543,
      emoji: '🥗',
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80',
    ),
  ];

  static const nearby = [
    RestaurantItem(
      name: 'Wok & Roll',
      cuisine: 'Паназия · Лапша · Рис',
      deliveryTime: '10–20',
      deliveryPrice: 'Бесплатно',
      rating: 4.5,
      reviewCount: 318,
      emoji: '🍜',
      imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&q=80',
      isNew: true,
    ),
    RestaurantItem(
      name: 'Coffee House',
      cuisine: 'Кофе · Выпечка · Завтраки',
      deliveryTime: '15–20',
      deliveryPrice: '39₽',
      rating: 4.7,
      reviewCount: 921,
      emoji: '☕',
      imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600&q=80',
    ),
    RestaurantItem(
      name: 'Sweet Dreams',
      cuisine: 'Десерты · Торты · Мороженое',
      deliveryTime: '20–30',
      deliveryPrice: '59₽',
      rating: 4.8,
      reviewCount: 445,
      emoji: '🧁',
      imageUrl: 'https://images.unsplash.com/photo-1486427944299-d1955d23e34d?w=600&q=80',
      isPromo: true,
      promoLabel: '2+1',
    ),
  ];
}
