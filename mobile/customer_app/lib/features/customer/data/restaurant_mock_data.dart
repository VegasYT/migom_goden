// Mock data for restaurant page - based on DB schema

class CatalogCategory {
  final int id;
  final String name;
  final int sortOrder;
  const CatalogCategory({required this.id, required this.name, required this.sortOrder});
}

class CatalogItemDiscount {
  final String label;
  final String type; // percent | fixed
  final int value;
  const CatalogItemDiscount({required this.label, required this.type, required this.value});
}

class CatalogItem {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final double price;
  final String? photoUrl;
  final CatalogItemDiscount? discount;
  const CatalogItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.photoUrl,
    this.discount,
  });

  double get finalPrice {
    if (discount == null) return price;
    if (discount!.type == 'percent') {
      return price * (1 - discount!.value / 100);
    } else {
      return price - discount!.value;
    }
  }
}

class ReviewItem {
  final int id;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  const ReviewItem({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class RestaurantDetail {
  final int id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String coverUrl;
  final List<String> cuisineTags;
  final double rating;
  final int reviewCount;
  final String deliveryTime;
  final String deliveryFee;
  final int? minOrderPrice;
  final int? freeDeliveryFrom;
  final bool isOpen;
  final List<CatalogCategory> categories;
  final List<CatalogItem> items;
  final List<ReviewItem> reviews;
  const RestaurantDetail({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.coverUrl,
    required this.cuisineTags,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.deliveryFee,
    this.minOrderPrice,
    this.freeDeliveryFrom,
    required this.isOpen,
    required this.categories,
    required this.items,
    required this.reviews,
  });
}

abstract final class RestaurantMockData {
  static final restaurant = RestaurantDetail(
    id: 1,
    name: 'Dodici Pizza',
    description:
        'Настоящая итальянская пицца на дровяной печи. Используем только свежие ингредиенты и тесто собственного приготовления.',
    coverUrl:
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80',
    cuisineTags: ['🍕 Пицца', '🍝 Паста', '🍰 Десерты'],
    rating: 4.9,
    reviewCount: 1240,
    deliveryTime: '25–35',
    deliveryFee: 'Бесплатно',
    minOrderPrice: 500,
    freeDeliveryFrom: 800,
    isOpen: true,
    categories: const [
      CatalogCategory(id: 1, name: 'Пицца', sortOrder: 1),
      CatalogCategory(id: 2, name: 'Паста', sortOrder: 2),
      CatalogCategory(id: 3, name: 'Закуски', sortOrder: 3),
      CatalogCategory(id: 4, name: 'Десерты', sortOrder: 4),
      CatalogCategory(id: 5, name: 'Напитки', sortOrder: 5),
    ],
    items: const [
      // Пицца
      CatalogItem(
        id: 1,
        categoryId: 1,
        name: 'Маргарита',
        description: 'Томатный соус, моцарелла, свежий базилик',
        price: 590,
        photoUrl:
            'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&q=80',
      ),
      CatalogItem(
        id: 2,
        categoryId: 1,
        name: 'Пепперони',
        description: 'Томатный соус, моцарелла, острая пепперони',
        price: 690,
        photoUrl:
            'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400&q=80',
        discount: CatalogItemDiscount(label: '-15%', type: 'percent', value: 15),
      ),
      CatalogItem(
        id: 3,
        categoryId: 1,
        name: 'Четыре сыра',
        description: 'Моцарелла, горгонзола, пармезан, рикотта',
        price: 790,
        photoUrl:
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400&q=80',
      ),
      CatalogItem(
        id: 4,
        categoryId: 1,
        name: 'Дьябола',
        description: 'Острая салями, перец чили, оливки',
        price: 720,
        photoUrl:
            'https://images.unsplash.com/photo-1555072956-7758afb20e8f?w=400&q=80',
      ),
      // Паста
      CatalogItem(
        id: 5,
        categoryId: 2,
        name: 'Карбонара',
        description: 'Спагетти, бекон, яйцо, пармезан, чёрный перец',
        price: 540,
        photoUrl:
            'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400&q=80',
      ),
      CatalogItem(
        id: 6,
        categoryId: 2,
        name: 'Болоньезе',
        description: 'Тальятелле, томатный соус, мясной рагу',
        price: 560,
        photoUrl:
            'https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?w=400&q=80',
        discount: CatalogItemDiscount(label: '-50₽', type: 'fixed', value: 50),
      ),
      CatalogItem(
        id: 7,
        categoryId: 2,
        name: 'Песто с курицей',
        description: 'Феттучини, соус песто, куриное филе, помидоры черри',
        price: 620,
        photoUrl:
            'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=400&q=80',
      ),
      // Закуски
      CatalogItem(
        id: 8,
        categoryId: 3,
        name: 'Брускетта',
        description: 'Хлеб чиабатта, томаты, базилик, оливковое масло',
        price: 290,
        photoUrl:
            'https://images.unsplash.com/photo-1572695157366-5e585ab2b69f?w=400&q=80',
      ),
      CatalogItem(
        id: 9,
        categoryId: 3,
        name: 'Сырные шарики',
        description: 'Жареная моцарелла в хрустящей панировке',
        price: 350,
        photoUrl:
            'https://images.unsplash.com/photo-1548340748-6fe4e5e0d90b?w=400&q=80',
      ),
      // Десерты
      CatalogItem(
        id: 10,
        categoryId: 4,
        name: 'Тирамису',
        description: 'Классический итальянский десерт с кофе и маскарпоне',
        price: 380,
        photoUrl:
            'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400&q=80',
      ),
      CatalogItem(
        id: 11,
        categoryId: 4,
        name: 'Панна котта',
        description: 'Сливочный десерт с ягодным соусом',
        price: 320,
        photoUrl:
            'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400&q=80',
      ),
      // Напитки
      CatalogItem(
        id: 12,
        categoryId: 5,
        name: 'Лимонад домашний',
        description: 'Лимон, мята, газированная вода',
        price: 220,
        photoUrl:
            'https://images.unsplash.com/photo-1523677011781-c91d1bbe2f9e?w=400&q=80',
      ),
      CatalogItem(
        id: 13,
        categoryId: 5,
        name: 'Итальянский кофе',
        description: 'Двойной эспрессо',
        price: 180,
        photoUrl:
            'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=400&q=80',
      ),
    ],
    reviews: [
      ReviewItem(
        id: 1,
        customerName: 'Алексей М.',
        rating: 5,
        comment: 'Отличная пицца, доставили быстро! Пепперони просто огонь.',
        createdAt: DateTime(2026, 3, 28),
      ),
      ReviewItem(
        id: 2,
        customerName: 'Мария К.',
        rating: 5,
        comment: 'Карбонара - лучшая что я пробовала. Обязательно закажу снова.',
        createdAt: DateTime(2026, 3, 25),
      ),
      ReviewItem(
        id: 3,
        customerName: 'Дмитрий В.',
        rating: 4,
        comment: 'Вкусно, но доставка немного задержалась. Тирамису - шедевр!',
        createdAt: DateTime(2026, 3, 20),
      ),
    ],
  );
}
