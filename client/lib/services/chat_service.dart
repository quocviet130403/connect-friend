import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';

class ChatService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;
  String? _token;
  Timer? _reconnectTimer;

  // Singleton - shared across screens
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  void connect(String token) {
    _token = token;
    if (_isConnected) return;
    _doConnect();
  }

  void _doConnect() {
    if (_token == null) return;

    try {
      final uri = Uri.parse('$wsUrl?token=$_token');
      debugPrint('WS connecting to: $uri');

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            debugPrint('WS received: ${msg['type']}');
            _messageController.add(msg);
          } catch (e) {
            debugPrint('WS parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('WS error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WS disconnected');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _isConnected = true;
      debugPrint('WS connected successfully');
    } catch (e) {
      debugPrint('WS connection failed: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isConnected && _token != null) {
        debugPrint('WS reconnecting...');
        _doConnect();
      }
    });
  }

  void joinRoom(String roomId) {
    debugPrint('WS joining room: $roomId');
    _send({'type': 'join_room', 'room_id': roomId});
  }

  void leaveRoom(String roomId) {
    _send({'type': 'leave_room', 'room_id': roomId});
  }

  void markRead(String roomId) {
    _send({'type': 'mark_read', 'room_id': roomId});
  }

  void sendMessage(String roomId, String content, {String messageType = 'text'}) {
    _send({
      'type': 'send_message',
      'room_id': roomId,
      'payload': {
        'content': content,
        'message_type': messageType,
      },
    });
  }

  void _send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      debugPrint('WS not connected, cannot send: ${data['type']}');
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
