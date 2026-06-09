import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

class WebSocketService {
  WebSocketChannel? _channel;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void connect(String userId) {
    if (_channel != null) return;

    final baseWsUrl = kIsWeb
        ? (dotenv.env['WS_URL_WEB'] ?? 'ws://127.0.0.1:8000/ws/notifications')
        : (dotenv.env['WS_URL_MOBILE'] ?? 'ws://10.0.2.2:8000/ws/notifications');
    final wsUrl = '$baseWsUrl?client_id=$userId';


    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _eventController.add(data);
          } catch (e) {
            debugPrint('Erreur décodage WS: $e');
          }
        },
        onDone: () {
          debugPrint('WebSocket déconnecté');
          _reconnect(userId);
        },
        onError: (error) {
          debugPrint('Erreur WebSocket: $error');
          _reconnect(userId);
        },
      );
    } catch (e) {
      debugPrint('Exception connexion WebSocket: $e');
      _reconnect(userId);
    }
  }

  void _reconnect(String userId) {
    _channel = null;
    Future.delayed(const Duration(seconds: 5), () {
      connect(userId);
    });
  }

  void sendGpsUpdate(double lat, double lng) {
    if (_channel != null) {
      _channel!.sink.add('GPS:$lat,$lng');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
