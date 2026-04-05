// Детальная модель товара для bottom sheet карточки.
// Соответствует таблицам: catalog_items, discounts, reviews из схемы БД.

class CatalogItemDetail {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? photoUrl;
  final CatalogItemDetailDiscount? discount;
  final List<CatalogItemReview> reviews;

  const CatalogItemDetail({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.photoUrl,
    this.discount,
    this.reviews = const [],
  });

  double get finalPrice {
    if (discount == null) return price;
    return switch (discount!.type) {
      DiscountType.percent => price * (1 - discount!.value / 100),
      DiscountType.fixed => price - discount!.value,
    };
  }

  bool get hasDiscount => discount != null;

  double get discountPercent {
    if (discount == null) return 0;
    return switch (discount!.type) {
      DiscountType.percent => discount!.value.toDouble(),
      DiscountType.fixed => (discount!.value / price * 100),
    };
  }

  double get averageRating {
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  }
}

enum DiscountType { percent, fixed }

class CatalogItemDetailDiscount {
  final String label;
  final DiscountType type;
  final int value;

  const CatalogItemDetailDiscount({
    required this.label,
    required this.type,
    required this.value,
  });
}

class CatalogItemReview {
  final int id;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const CatalogItemReview({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}
