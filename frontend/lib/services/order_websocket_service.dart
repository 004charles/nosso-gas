import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrderWebSocketService {
  WebSocketChannel? _channel;
  final String _baseUrl = "ws://127.0.0.1:8000/ws/orders/"; 
  
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  bool get isConnected => _channel != null;

  void connect(int userId) {
    _channel = WebSocketChannel.connect(
      Uri.parse("$_baseUrl?user_id=$userId"),
    );

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      _controller.add(data);
    }, onError: (error) {
      print("Erro no WebSocket: $error");
      _channel = null;
    }, onDone: () {
      print("WebSocket fechado");
      _channel = null;
    });
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
