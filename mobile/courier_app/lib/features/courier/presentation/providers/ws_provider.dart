import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ws_service.dart';
import 'active_order_provider.dart';
import 'incoming_order_provider.dart';

/// Initializes WebSocket connection and routes messages to appropriate providers.
void initWsListener(Ref ref) {
  WsService.instance.connect(
    onMessage: (topic, payload) {
      switch (topic) {
        case 'courier.order_offer':
          ref.read(incomingOrderProvider.notifier).receiveFromWs(payload);
          break;
        case 'order.status_updated':
          final status = payload['status'] as String?;
          if (status == 'received') {
            // Customer confirmed delivery
            ref.read(activeOrderProvider.notifier).confirmDelivery();
          }
          break;
      }
    },
  );
}

final wsInitProvider = Provider<void>((ref) {
  initWsListener(ref);
  ref.onDispose(() => WsService.instance.disconnect());
});
