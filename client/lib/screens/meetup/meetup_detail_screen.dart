import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class MeetupDetailScreen extends StatefulWidget {
  final String meetupId;
  const MeetupDetailScreen({super.key, required this.meetupId});

  @override
  State<MeetupDetailScreen> createState() => _MeetupDetailScreenState();
}

class _MeetupDetailScreenState extends State<MeetupDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _meetup;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.getMeetup(widget.meetupId);
      setState(() {
        _meetup = res['data'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_meetup?['title'] ?? 'Cuộc hẹn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _meetup?['title'] ?? '',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_meetup?['description'] != null)
                      Text(_meetup!['description'], style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                    const SizedBox(height: 16),

                    // Location
                    _DetailRow(
                      icon: Icons.place,
                      iconColor: AppTheme.accent,
                      title: _meetup?['place_name'] ?? '',
                      subtitle: _meetup?['place_address'] ?? '',
                    ),
                    const Divider(height: 24),

                    // Time
                    _DetailRow(
                      icon: Icons.access_time,
                      iconColor: AppTheme.secondary,
                      title: _formatDate(_meetup?['start_time']),
                      subtitle: _formatTime(_meetup?['start_time']),
                    ),
                    const Divider(height: 24),

                    // Members
                    _DetailRow(
                      icon: Icons.people,
                      iconColor: AppTheme.primary,
                      title: '${_meetup?['current_count'] ?? 0}/${_meetup?['max_members'] ?? 0} người tham gia',
                      subtitle: _meetup?['status'] == 'full' ? 'Đã đầy' : 'Còn chỗ',
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Tags
            if (_meetup?['tags'] != null && (_meetup!['tags'] as List).isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_meetup!['tags'] as List).map((tag) => Chip(
                  label: Text('#$tag', style: const TextStyle(fontSize: 13)),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                )).toList(),
              ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _meetup?['status'] == 'open' ? () => _joinMeetup() : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Tham gia'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _meetup?['chat_room_id'] != null
                        ? () => context.push('/chat/${_meetup!['chat_room_id']}?title=${Uri.encodeComponent(_meetup?['title'] ?? 'Chat')}')
                        : null,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Group Chat'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  void _joinMeetup() async {
    try {
      await _api.joinMeetup(widget.meetupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tham gia! 🎉 Mở chat nào!'), backgroundColor: AppTheme.success),
        );
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  String _formatDate(dynamic time) {
    if (time == null) return '';
    try {
      final dt = DateTime.parse(time.toString());
      final weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
      return '${weekdays[dt.weekday - 1]}, ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _DetailRow({required this.icon, required this.iconColor, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
