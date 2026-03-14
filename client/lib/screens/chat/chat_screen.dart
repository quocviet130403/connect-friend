import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String meetupTitle;
  const ChatScreen({super.key, required this.roomId, required this.meetupTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
  final _chatService = ChatService();
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  StreamSubscription? _sub;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWS();
  }

  void _connectWS() {
    final token = _api.token;
    if (token != null) {
      // Decode user ID from token for message alignment
      _myUserId = _decodeUserIdFromToken(token);

      _chatService.connect(token);
      _chatService.joinRoom(widget.roomId);

      _sub = _chatService.messages.listen((msg) {
        if (mounted && msg['room_id'] == widget.roomId) {
          final type = msg['type'];
          if (type == 'new_message') {
            final data = msg['data'] ?? msg;
            setState(() {
              _messages.insert(0, data is Map<String, dynamic> ? data : <String, dynamic>{});
            });
            _scrollToBottom();
          }
        }
      });
    }
  }

  String? _decodeUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      // Add padding
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = Uri.decodeFull(
        String.fromCharCodes(
          Uri.parse('data:text/plain;base64,$payload').data!.contentAsBytes(),
        ),
      );
      // Manual simple JSON parse for user_id
      final match = RegExp(r'"user_id"\s*:\s*"([^"]+)"').firstMatch(decoded);
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadMessages() async {
    try {
      final res = await _api.getMessages(widget.roomId);
      setState(() {
        _messages = ((res['data'] as List?) ?? [])
            .map((m) => m as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0, duration: 200.ms, curve: Curves.easeOut);
      }
    });
  }

  bool _isMyMessage(Map<String, dynamic> msg) {
    final senderId = msg['sender_id']?.toString() ?? '';
    return senderId == _myUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.meetupTitle, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Icon(
                  _chatService.isConnected ? Icons.circle : Icons.circle_outlined,
                  size: 8,
                  color: _chatService.isConnected ? AppTheme.success : AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _chatService.isConnected ? 'Đang kết nối' : 'Mất kết nối',
                  style: TextStyle(
                    fontSize: 11,
                    color: _chatService.isConnected ? AppTheme.success : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text('Chưa có tin nhắn', style: TextStyle(color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Gửi lời chào đầu tiên! 👋', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isSystem = msg['message_type'] == 'system';
                          if (isSystem) return _SystemMessage(content: msg['content'] ?? '');
                          return _MessageBubble(
                            message: msg,
                            isMine: _isMyMessage(msg),
                          );
                        },
                      ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(top: BorderSide(color: AppTheme.borderDark)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.cardDark,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    // Optimistic: show message immediately
    setState(() {
      _messages.insert(0, {
        'content': text,
        'sender_id': _myUserId ?? '',
        'message_type': 'text',
        'created_at': DateTime.now().toIso8601String(),
      });
    });

    _chatService.sendMessage(widget.roomId, text);
    _messageCtrl.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _chatService.leaveRoom(widget.roomId);
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMine ? 60 : 0,
          right: isMine ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.cardDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomRight: Radius.circular(isMine ? 4 : 18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
          ),
          border: Border.all(
            color: isMine ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.borderDark,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message['content'] ?? '', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              _formatTime(message['created_at']),
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    try {
      final dt = DateTime.parse(time.toString());
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _SystemMessage extends StatelessWidget {
  final String content;
  const _SystemMessage({required this.content});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(content, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ),
    );
  }
}
