import 'package:latlong2/latlong.dart';

// Legacy enums used by UI widgets (kept for compatibility)
enum OrderStatus {
  assembling,
  readyForPickup,
  courierPickedUp,
  nearYou,
  delivered,
  cancelled,
  // API statuses
  newOrder,
  assigned,
  inDelivery,
  received,
}

enum PaymentMethod { card, cash, sbp }

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => price * quantity;
}

class CourierModel {
  final String name;
  final String avatarUrl;
  final String phone;
  final double rating;
  final LatLng location;

  const CourierModel({
    required this.name,
    required this.avatarUrl,
    required this.phone,
    required this.rating,
    required this.location,
  });
}

class ActiveOrderModel {
  final String id;
  final String restaurantName;
  final String restaurantAddress;
  final String deliveryAddress;
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final PaymentMethod paymentMethod;
  final String estimatedTime;
  final LatLng restaurantLocation;
  final LatLng deliveryLocation;
  final CourierModel? courier;

  const ActiveOrderModel({
    required this.id,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.deliveryAddress,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.estimatedTime,
    required this.restaurantLocation,
    required this.deliveryLocation,
    this.courier,
  });
}

class PastOrderModel {
  final String id;
  final String restaurantName;
  final String restaurantEmoji;
  final String date;
  final double total;
  final int itemsCount;
  final OrderStatus status;
  final List<OrderItem> items;
  // причина отмены, если заказ отменил ресторан
  final String? cancelReason;

  const PastOrderModel({
    required this.id,
    required this.restaurantName,
    required this.restaurantEmoji,
    required this.date,
    required this.total,
    required this.itemsCount,
    required this.status,
    required this.items,
    this.cancelReason,
  });
}

// API order model from the server
class ApiOrderModel {
  final int id;
  final int companyId;
  final String status;
  final String deliveryType;
  final double totalPrice;
  final double deliveryFee;
  final String? comment;
  final String? cancelReason;
  final bool leaveAtDoor;
  final String createdAt;
  final int outletId;
  final String? outletName;
  final String? outletAddress;
  final int? courierId;
  final Map<String, dynamic>? deliveryAddressJson;
  final List<ApiOrderItem> items;

  const ApiOrderModel({
    required this.id,
    required this.companyId,
    required this.status,
    required this.deliveryType,
    required this.totalPrice,
    required this.deliveryFee,
    this.comment,
    this.cancelReason,
    this.leaveAtDoor = false,
    required this.createdAt,
    required this.outletId,
    this.outletName,
    this.outletAddress,
    this.courierId,
    this.deliveryAddressJson,
    required this.items,
  });

  String get deliveryAddressLabel {
    if (deliveryAddressJson == null) return '';
    return deliveryAddressJson!['address'] as String? ?? '';
  }

  double? get deliveryLatitude {
    final v = deliveryAddressJson?['latitude'];
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  double? get deliveryLongitude {
    final v = deliveryAddressJson?['longitude'];
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  OrderStatus get orderStatus => switch (status) {
    'assembling' => OrderStatus.assembling,
    'ready_for_pickup' => OrderStatus.readyForPickup,
    'in_delivery' => OrderStatus.inDelivery,
    'delivered' => OrderStatus.delivered,
    'cancelled' => OrderStatus.cancelled,
    'assigned' => OrderStatus.assigned,
    'received' => OrderStatus.received,
    _ => OrderStatus.newOrder,
  };

  bool get isActive => !['delivered', 'cancelled', 'received'].contains(status);

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн',
                      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  factory ApiOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return ApiOrderModel(
      id: json['id'] as int,
      companyId: json['company_id'] as int? ?? 0,
      status: json['status'] as String? ?? 'new',
      deliveryType: json['delivery_type'] as String? ?? 'delivery',
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0,
      comment: json['comment'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      leaveAtDoor: json['leave_at_door'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      outletId: json['outlet_id'] as int? ?? 0,
      outletName: json['outlet_name'] as String?,
      outletAddress: json['outlet_address'] as String?,
      courierId: json['courier_id'] as int?,
      deliveryAddressJson: json['delivery_address'] as Map<String, dynamic>?,
      items: itemsList
          .map((e) => ApiOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  PastOrderModel toPastOrderModel({String? restaurantName}) {
    return PastOrderModel(
      id: id.toString(),
      restaurantName: restaurantName ?? outletName ?? 'Заведение',
      restaurantEmoji: '🍽️',
      date: formattedDate,
      total: totalPrice,
      itemsCount: items.fold(0, (sum, i) => sum + i.quantity),
      status: orderStatus,
      items: items
          .map((i) => OrderItem(name: i.name, quantity: i.quantity, price: i.price))
          .toList(),
      cancelReason: cancelReason,
    );
  }
}

class ApiOrderItem {
  final int id;
  final int catalogItemId;
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  const ApiOrderItem({
    required this.id,
    required this.catalogItemId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory ApiOrderItem.fromJson(Map<String, dynamic> json) {
    return ApiOrderItem(
      id: json['id'] as int,
      catalogItemId: json['catalog_item_id'] as int,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: double.tryParse(json['price'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
    );
  }
}
