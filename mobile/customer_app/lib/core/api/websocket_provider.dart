import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'websocket_service.dart';

final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.disconnect);
  return service;
});

// Стрим событий изменения статуса заказа
final orderStatusEventProvider = StreamProvider<WsEvent>((ref) {
  final ws = ref.watch(websocketServiceProvider);
  return ws.on('order.status_updated');
});

// Стрим событий назначения курьера
final courierAssignedEventProvider = StreamProvider<WsEvent>((ref) {
  final ws = ref.watch(websocketServiceProvider);
  return ws.on('courier.assigned');
});

// Стрим геопозиции курьера
final courierLocationEventProvider = StreamProvider<WsEvent>((ref) {
  final ws = ref.watch(websocketServiceProvider);
  return ws.on('courier.location_updated');
});
