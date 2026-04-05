import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/order_history_model.dart';

// NOTE: The delivery service API does not have a dedicated endpoint for
// courier order history (delivered/received orders). The only available
// endpoints are:
//   GET /courier/orders/available  - currently available orders in zone
//   GET /courier/orders/active     - current active order
//
// Order history is therefore NOT available from the API and is kept as
// empty list. See COMMENTED_FEATURES.md §2 for details.

final orderHistoryProvider =
    AsyncNotifierProvider<OrderHistoryNotifier, List<DeliveredOrderModel>>(
  OrderHistoryNotifier.new,
);

class OrderHistoryNotifier
    extends AsyncNotifier<List<DeliveredOrderModel>> {
  @override
  Future<List<DeliveredOrderModel>> build() async {
    // No API endpoint available - return empty list
    return [];
  }
}
