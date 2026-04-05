class CartItemModel {
  final int id;
  final int catalogItemId;
  final int companyId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;
  final String? photoUrl;

  const CartItemModel({
    required this.id,
    required this.catalogItemId,
    required this.companyId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.photoUrl,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int,
      catalogItemId: json['catalog_item_id'] as int,
      companyId: json['company_id'] as int,
      name: json['name'] as String? ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class CartModel {
  final int companyId;
  final String? companyName;
  final List<CartItemModel> items;
  final double total;

  const CartModel({
    required this.companyId,
    this.companyName,
    required this.items,
    required this.total,
  });

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return CartModel(
      companyId: json['company_id'] as int,
      companyName: json['company_name'] as String?,
      items: itemsList
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: double.tryParse(json['total'].toString()) ?? 0,
    );
  }
}

class AllCartsResponse {
  final List<CartModel> carts;
  final double grandTotal;

  const AllCartsResponse({required this.carts, required this.grandTotal});

  int get totalItems => carts.fold(0, (sum, c) => sum + c.totalItems);

  factory AllCartsResponse.fromJson(Map<String, dynamic> json) {
    final cartsList = json['carts'] as List<dynamic>? ?? [];
    return AllCartsResponse(
      carts: cartsList
          .map((e) => CartModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      grandTotal: double.tryParse(json['grand_total'].toString()) ?? 0,
    );
  }
}
