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

  // Profile cache: userId -> {display_name, avatar_url}
  final Map<String, Map<String, dynamic>> _profiles = {};
  // Read positions cache: messageIndex -> list of reader userIds
  Map<int, List<String>> _readPositions = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _connectWS();
  }

  void _connectWS() {
    final token = _api.token;
    if (token != null) {
      _myUserId = _decodeUserIdFromToken(token);

      _chatService.connect(token);
      _chatService.joinRoom(widget.roomId);

      _sub = _chatService.messages.listen((msg) {
        if (mounted && msg['room_id'] == widget.roomId) {
          final type = msg['type'];

          if (type == 'new_message') {
            final senderId = msg['sender_id']?.toString() ?? '';
            // Skip messages from self — already shown via optimistic insert
            if (senderId == _myUserId) return;

            final data = msg['data'] ?? msg;
            if (data is Map<String, dynamic>) {
              setState(() => _messages.insert(0, data));
              _ensureProfile(senderId);
              _scrollToBottom();
              // Auto mark read since chat is open
              _chatService.markRead(widget.roomId);
            }
          } else if (type == 'read_update') {
            // Someone read messages — reload to get updated read_by data
            _reloadReadReceipts();
          }
        }
      });

      // Mark all existing messages as read when entering chat
      Future.delayed(const Duration(milliseconds: 500), () {
        _chatService.markRead(widget.roomId);
      });
    }
  }

  String? _decodeUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = Uri.decodeFull(
        String.fromCharCodes(
          Uri.parse('data:text/plain;base64,$payload').data!.contentAsBytes(),
        ),
      );
      final match = RegExp(r'"user_id"\s*:\s*"([^"]+)"').firstMatch(decoded);
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadMessages() async {
    try {
      final res = await _api.getMessages(widget.roomId);
      final messages = ((res['data'] as List?) ?? [])
          .map((m) => m as Map<String, dynamic>)
          .toList();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _loadProfiles(messages);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reloadReadReceipts() async {
    try {
      final res = await _api.getMessages(widget.roomId);
      final messages = ((res['data'] as List?) ?? [])
          .map((m) => m as Map<String, dynamic>)
          .toList();
      if (mounted) {
        setState(() => _messages = messages);
      }
    } catch (_) {}
  }

  Future<void> _loadProfiles(List<Map<String, dynamic>> messages) async {
    final senderIds = messages
        .map((m) => m['sender_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty && id != _myUserId && !_profiles.containsKey(id))
        .toSet();

    for (final id in senderIds) {
      _ensureProfile(id);
    }
  }

  Future<void> _ensureProfile(String userId) async {
    if (userId.isEmpty || _profiles.containsKey(userId)) return;

    try {
      final res = await _api.getProfile(userId);
      final data = res['data'];
      if (data is Map<String, dynamic> && mounted) {
        setState(() => _profiles[userId] = data);
      }
    } catch (_) {}
  }

  String _getSenderName(String senderId) {
    if (senderId == _myUserId) return 'Bạn';
    return _profiles[senderId]?['display_name'] ?? 'Thành viên';
  }

  String _getSenderAvatar(String senderId) {
    return _profiles[senderId]?['avatar_url'] ?? '';
  }

  /// Compute which readers should show under which message index.
  /// Each reader's avatar appears at their NEWEST read message only (like Messenger).
  /// Returns map: messageIndex → list of userIds
  Map<int, List<String>> _computeReadPositions() {
    final Map<String, int> readerNewestIndex = {};

    for (int i = 0; i < _messages.length; i++) {
      final readBy = _messages[i]['read_by'] as List?;
      if (readBy == null) continue;

      final senderId = _messages[i]['sender_id']?.toString() ?? '';

      for (final r in readBy) {
        final uid = (r as Map<String, dynamic>)['user_id']?.toString() ?? '';
        if (uid.isEmpty || uid == _myUserId || uid == senderId) continue;

        // Index 0 = newest (reversed list). First occurrence = newest read.
        if (!readerNewestIndex.containsKey(uid)) {
          readerNewestIndex[uid] = i;
        }
      }
    }

    // Invert: messageIndex → list of reader userIds
    final Map<int, List<String>> result = {};
    for (final entry in readerNewestIndex.entries) {
      result.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    return result;
  }

  /// Get readers whose "last read" is exactly this message
  List<String> _getReadByUsers(int messageIndex) {
    return _readPositions[messageIndex] ?? [];
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
    // Recompute read positions on every build
    _readPositions = _computeReadPositions();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.group, size: 16, color: AppTheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.meetupTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _chatService.isConnected ? AppTheme.success : AppTheme.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _chatService.isConnected ? 'Đang hoạt động' : 'Mất kết nối',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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

                          final isMine = _isMyMessage(msg);
                          final senderId = msg['sender_id']?.toString() ?? '';
                          final readByUsers = _getReadByUsers(index);

                          // Show sender name if previous message is from a different sender
                          bool showSender = false;
                          if (!isMine) {
                            if (index == _messages.length - 1) {
                              showSender = true;
                            } else {
                              final prevMsg = _messages[index + 1];
                              showSender = prevMsg['sender_id']?.toString() != senderId;
                            }
                          }

                          return _MessageBubble(
                            message: msg,
                            isMine: isMine,
                            senderName: showSender ? _getSenderName(senderId) : null,
                            avatarUrl: !isMine ? _getSenderAvatar(senderId) : null,
                            showAvatar: showSender,
                            readByAvatars: readByUsers
                                .map((uid) => _ReadAvatarInfo(
                                      name: _getSenderName(uid),
                                      avatarUrl: _getSenderAvatar(uid),
                                    ))
                                .toList(),
                          );
                        },
                      ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              border: Border(top: BorderSide(color: AppTheme.border.withValues(alpha: 0.5), width: 0.5)),
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
                        hintText: 'Aa',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
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

class _ReadAvatarInfo {
  final String name;
  final String avatarUrl;
  const _ReadAvatarInfo({required this.name, required this.avatarUrl});
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMine;
  final String? senderName;
  final String? avatarUrl;
  final bool showAvatar;
  final List<_ReadAvatarInfo> readByAvatars;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.senderName,
    this.avatarUrl,
    this.showAvatar = false,
    this.readByAvatars = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: isMine ? 60 : 0,
        right: isMine ? 0 : 60,
      ),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name
          if (senderName != null)
            Padding(
              padding: EdgeInsets.only(left: isMine ? 0 : 44, bottom: 4, top: 8),
              child: Text(
                senderName!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
            ),

          Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: showAvatar
                      ? CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty) ? NetworkImage(avatarUrl!) : null,
                          child: (avatarUrl == null || avatarUrl!.isEmpty)
                              ? Text(
                                  (senderName ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                )
                              : null,
                        )
                      : const SizedBox(width: 32),
                ),

              // Bubble
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? AppTheme.myBubble : AppTheme.otherBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['content'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          color: isMine ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatTime(message['created_at']),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMine ? Colors.white.withValues(alpha: 0.6) : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Read receipts — small avatars under the message
          if (readByAvatars.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isMine ? 0 : 44,
                bottom: 4,
              ),
              child: GestureDetector(
                onTap: () => _showReadByDialog(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stacked avatars
                    SizedBox(
                      height: 18,
                      width: readByAvatars.length * 14.0 + 4,
                      child: Stack(
                        children: readByAvatars.take(5).toList().asMap().entries.map((entry) {
                          final i = entry.key;
                          final info = entry.value;
                          return Positioned(
                            left: i * 12.0,
                            child: CircleAvatar(
                              radius: 9,
                              backgroundColor: AppTheme.bg,
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                                backgroundImage: info.avatarUrl.isNotEmpty ? NetworkImage(info.avatarUrl) : null,
                                child: info.avatarUrl.isEmpty
                                    ? Text(info.name[0].toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đã xem',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showReadByDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đã xem', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: readByAvatars.map((info) {
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                backgroundImage: info.avatarUrl.isNotEmpty ? NetworkImage(info.avatarUrl) : null,
                child: info.avatarUrl.isEmpty
                    ? Text(info.name[0].toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary))
                    : null,
              ),
              title: Text(info.name, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
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
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(content, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ),
    );
  }
}
