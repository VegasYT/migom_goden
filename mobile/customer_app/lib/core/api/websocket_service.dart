import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';

class WsEvent {
  final String topic;
  final Map<String, dynamic> payload;

  const WsEvent({required this.topic, required this.payload});

  factory WsEvent.fromJson(Map<String, dynamic> json) => WsEvent(
        topic: json['topic'] as String,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
      );
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  final _storage = const FlutterSecureStorage();
  WebSocketChannel? _channel;
  final _controller = StreamController<WsEvent>.broadcast();
  Timer? _reconnectTimer;
  bool _disposed = false;

  Stream<WsEvent> get events => _controller.stream;

  Stream<WsEvent> on(String topic) =>
      events.where((e) => e.topic == topic);

  Future<void> connect() async {
    if (_disposed) return;
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    try {
      // Строим ws:// URL из kBaseUrl (https://host/api/v1 → wss://host/ws)
      final baseUri = Uri.parse(kBaseUrl);
      final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
      final wsUri = Uri(
        scheme: wsScheme,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
        path: '/ws',
        queryParameters: {'token': token},
      );

      _channel = WebSocketChannel.connect(wsUri);
      print('[WS] connecting to $wsUri');

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            print('[WS] event: ${json['topic']}');
            _controller.add(WsEvent.fromJson(json));
          } catch (e) {
            print('[WS] parse error: $e');
          }
        },
        onDone: () {
          print('[WS] connection closed, reconnecting...');
          _scheduleReconnect();
        },
        onError: (e) {
          print('[WS] error: $e');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('[WS] connect error: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), connect);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
  }
}
