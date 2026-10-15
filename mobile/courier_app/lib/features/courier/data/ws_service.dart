import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/api/api_client.dart';

typedef WsMessageCallback = void Function(String topic, Map<String, dynamic> payload);

class WsService {
  WsService._();
  static final WsService instance = WsService._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  WsMessageCallback? _onMessage;
  bool _connected = false;
  Timer? _reconnectTimer;

  bool get isConnected => _connected;

  Future<void> connect({required WsMessageCallback onMessage}) async {
    _onMessage = onMessage;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    // access-токен живёт 15 минут: запрос через dio обновит истёкший токен до подключения
    try {
      await ApiClient.instance.dio.get('/couriers/me');
    } catch (_) {}
    final token = await ApiClient.instance.getAccessToken();
    if (token == null) return;

    _sub?.cancel();
    try {
      // Build ws(s) URL from the base HTTP URL:
      // https://host/api/v1 → wss://host/ws
      // http://host/api/v1  → ws://host/ws
      final baseUri = Uri.parse(ApiClient.baseUrl);
      final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
      final wsUri = Uri(
        scheme: wsScheme,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
        path: '/ws',
        queryParameters: {'token': token},
      );

      _channel = WebSocketChannel.connect(wsUri);
      _connected = true;
      _sub = _channel!.stream.listen(
        _handleMessage,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: false,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final topic = data['topic'] as String?;
      final payload = data['payload'] as Map<String, dynamic>?;
      if (topic != null && payload != null) {
        _onMessage?.call(topic, payload);
      }
    } catch (_) {}
  }

  void _onDisconnected() {
    _connected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), _doConnect);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _connected = false;
    _onMessage = null;
  }
}
