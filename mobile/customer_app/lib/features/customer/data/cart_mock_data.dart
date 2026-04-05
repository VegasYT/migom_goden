// Mock data - будет заменено на реальный API (order_items + menu_items)

class CartItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String emoji;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    required this.imageUrl,
    this.quantity = 1,
  });

  double get total => price * quantity;
}

class RestaurantCart {
  final String restaurantId;
  final String restaurantName;
  final String restaurantEmoji;
  final String restaurantImageUrl;
  final List<CartItem> items;
  final double freeDeliveryFrom;
  final double deliveryFee;
  final double minOrderPrice;

  RestaurantCart({
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantEmoji,
    required this.restaurantImageUrl,
    required this.items,
    this.freeDeliveryFrom = 800,
    this.deliveryFee = 49,
    this.minOrderPrice = 300,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.total);
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);
}

abstract final class CartMockData {
  static const promoCode = 'MIGOM20';
  static const promoDiscount = 0.20; // 20%

  static List<RestaurantCart> carts = [
    RestaurantCart(
      restaurantId: 'dodici',
      restaurantName: 'Dodici Pizza',
      restaurantEmoji: '🍕',
      restaurantImageUrl:
          'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=200&q=80',
      freeDeliveryFrom: 800,
      deliveryFee: 0,
      items: [
        CartItem(
          id: '1',
          name: 'Пицца Маргарита',
          description: 'Томатный соус, моцарелла, базилик',
          price: 590,
          emoji: '🍕',
          imageUrl:
              'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=200&q=80',
          quantity: 1,
        ),
        CartItem(
          id: '2',
          name: 'Картофель фри',
          description: 'Хрустящий, с соусом на выбор',
          price: 180,
          emoji: '🍟',
          imageUrl:
              'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=200&q=80',
          quantity: 1,
        ),
      ],
    ),
    RestaurantCart(
      restaurantId: 'sushi',
      restaurantName: 'Sushi Master',
      restaurantEmoji: '🍣',
      restaurantImageUrl:
          'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=200&q=80',
      freeDeliveryFrom: 1000,
      deliveryFee: 49,
      items: [
        CartItem(
          id: '3',
          name: 'Ролл Филадельфия',
          description: 'Лосось, сливочный сыр, огурец',
          price: 420,
          emoji: '🍣',
          imageUrl:
              'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=200&q=80',
          quantity: 2,
        ),
        CartItem(
          id: '4',
          name: 'Капучино',
          description: 'Двойной эспрессо, молочная пена',
          price: 220,
          emoji: '☕',
          imageUrl:
              'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=200&q=80',
          quantity: 1,
        ),
      ],
    ),
  ];
}
