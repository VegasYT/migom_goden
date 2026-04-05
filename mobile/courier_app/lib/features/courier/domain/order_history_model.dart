class DeliveredOrderItem {
  final String name;
  final int quantity;

  const DeliveredOrderItem({required this.name, required this.quantity});
}

class DeliveredOrderModel {
  final String id;
  final String restaurantName;
  final String restaurantEmoji;
  final String customerAddress;
  final String date;
  final String time;
  final double payment;
  final double distanceKm;
  final List<DeliveredOrderItem> items;

  const DeliveredOrderModel({
    required this.id,
    required this.restaurantName,
    required this.restaurantEmoji,
    required this.customerAddress,
    required this.date,
    required this.time,
    required this.payment,
    required this.distanceKm,
    required this.items,
  });
}
