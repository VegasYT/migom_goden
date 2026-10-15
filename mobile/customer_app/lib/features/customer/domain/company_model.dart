class CompanyModel {
  final int id;
  final String name;
  final String? description;
  final String? logoUrl;
  final bool isActive;

  const CompanyModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.isActive = true,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class OutletModel {
  final int id;
  final int companyId;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? deliveryFee;
  final int? freeDeliveryFrom;
  final int? minOrderPrice;
  final bool isActive;
  final String? opensAt;
  final String? closesAt;
  final String? timezone;

  const OutletModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.deliveryFee,
    this.freeDeliveryFrom,
    this.minOrderPrice,
    this.isActive = true,
    this.opensAt,
    this.closesAt,
    this.timezone,
  });

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    return OutletModel(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
      freeDeliveryFrom: json['free_delivery_from'] as int?,
      minOrderPrice: json['min_order_price'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      opensAt: json['opens_at'] as String?,
      closesAt: json['closes_at'] as String?,
      timezone: json['timezone'] as String?,
    );
  }
}

class MenuCategory {
  final int id;
  final String name;
  final int sortOrder;
  final List<MenuItem> items;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.items,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return MenuCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      items: itemsList
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MenuItem {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final double price;
  final String? photoUrl;
  final bool isAvailable;
  final int? stockCount;
  final MenuItemDiscount? discount;

  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.photoUrl,
    this.isAvailable = true,
    this.stockCount,
    this.discount,
  });

  double get finalPrice {
    if (discount == null) return price;
    if (discount!.discountType == 'percent') {
      return price * (1 - discount!.value / 100);
    } else {
      return price - discount!.value;
    }
  }

  bool get hasDiscount => discount != null;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final discountJson = json['discount'] as Map<String, dynamic>?;
    return MenuItem(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      photoUrl: json['photo_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      stockCount: json['stock_count'] as int?,
      discount: discountJson != null ? MenuItemDiscount.fromJson(discountJson) : null,
    );
  }
}

class MenuItemDiscount {
  final String label;
  final String discountType;
  final double value;

  const MenuItemDiscount({
    required this.label,
    required this.discountType,
    required this.value,
  });

  factory MenuItemDiscount.fromJson(Map<String, dynamic> json) {
    return MenuItemDiscount(
      label: json['label'] as String? ?? '',
      discountType: json['discount_type'] as String? ?? 'percent',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CompanyMenu {
  final int companyId;
  final String companyName;
  final String? logoUrl;
  final String? description;
  final double? rating;
  final int? reviewCount;
  final List<MenuCategory> categories;
  // горячие предложения Goden в меню заведения: товары, которые стоит продвигать
  final List<int> hotItemIds;

  const CompanyMenu({
    required this.companyId,
    required this.companyName,
    this.logoUrl,
    this.description,
    this.rating,
    this.reviewCount,
    required this.categories,
    this.hotItemIds = const [],
  });

  List<MenuItem> get allItems =>
      categories.expand((c) => c.items).toList();

  factory CompanyMenu.fromJson(Map<String, dynamic> json) {
    final categoriesJson = json['categories'] as List<dynamic>? ?? [];
    return CompanyMenu(
      companyId: json['company_id'] as int? ?? json['id'] as int? ?? 0,
      companyName: json['company_name'] as String? ?? json['name'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      categories: categoriesJson
          .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      hotItemIds: (json['hot_offers'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>)['catalog_item_id'] as int)
          .toList(),
    );
  }
}
