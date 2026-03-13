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

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWS();
  }

  void _connectWS() {
    final token = _api.token;
    if (token != null) {
      _chatService.connect(token);
      _chatService.joinRoom(widget.roomId);
      _sub = _chatService.messages.listen((msg) {
        if (msg['room_id'] == widget.roomId && msg['type'] == 'new_message') {
          setState(() {
            _messages.insert(0, msg['data'] as Map<String, dynamic>);
          });
          _scrollToBottom();
        }
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.meetupTitle, style: const TextStyle(fontSize: 16)),
            Text(
              '${_messages.length} tin nhắn',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                          return _MessageBubble(message: msg);
                        },
                      ),
          ),

          // Input
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

    _chatService.sendMessage(widget.roomId, text);
    _messageCtrl.clear();
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
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // Simple styling — in production you'd compare sender_id to current user
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['content'] ?? '',
              style: const TextStyle(fontSize: 15),
            ),
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
