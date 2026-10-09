import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService {
  static SocketService? _instance;
  WebSocketChannel? _channel;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _eventController.stream;

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  SocketService._();

  void connect(
      String wsUrl, String roomCode, String username, String clientId) {
    try {
      disconnect();
      final uri = Uri.parse('$wsUrl?roomCode=$roomCode'
          '&username=${Uri.encodeQueryComponent(username)}'
          '&clientId=${Uri.encodeQueryComponent(clientId)}');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data is Map<String, dynamic>) {
              _eventController.add(data);
            }
          } catch (e) {
            debugPrint('Socket Decode Error: $e');
          }
        },
        onError: (err) => debugPrint('Socket Error: $err'),
        onDone: () => debugPrint('Socket Connection Closed'),
      );
    } catch (e) {
      debugPrint('Socket Connection Exception: $e');
    }
  }

  void sendEvent(String eventType, Map<String, dynamic> payload) {
    if (_channel != null) {
      final message = jsonEncode({'type': eventType, ...payload});
      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
