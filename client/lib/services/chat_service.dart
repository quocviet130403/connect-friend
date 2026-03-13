import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';

class ChatService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  void connect(String token) {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl?token=$token'),
      );

      _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            _messageController.add(msg);
          } catch (e) {
            debugPrint('WS parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('WS error: $error');
          _isConnected = false;
          // Reconnect after 3 seconds
          Future.delayed(const Duration(seconds: 3), () => connect(token));
        },
        onDone: () {
          _isConnected = false;
          debugPrint('WS disconnected');
        },
      );

      _isConnected = true;
      debugPrint('WS connected');
    } catch (e) {
      debugPrint('WS connection error: $e');
    }
  }

  void joinRoom(String roomId) {
    _send({
      'type': 'join_room',
      'room_id': roomId,
    });
  }

  void leaveRoom(String roomId) {
    _send({
      'type': 'leave_room',
      'room_id': roomId,
    });
  }

  void sendMessage(String roomId, String content, {String messageType = 'text'}) {
    _send({
      'type': 'send_message',
      'room_id': roomId,
      'payload': jsonEncode({
        'content': content,
        'message_type': messageType,
      }),
    });
  }

  void _send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
