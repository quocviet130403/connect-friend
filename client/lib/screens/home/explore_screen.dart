import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _api = ApiService();
  List<dynamic> _meetups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetups();
  }

  Future<void> _loadMeetups() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getMeetups();
      setState(() {
        _meetups = (res['data'] as List?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.connect_without_contact, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Khám phá'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMeetups,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _meetups.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _meetups.length,
                    itemBuilder: (context, index) => _MeetupCard(
                      meetup: _meetups[index] as Map<String, dynamic>,
                    ).animate().slideY(begin: 0.1, delay: Duration(milliseconds: index * 80)).fadeIn(),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.explore, size: 48, color: AppTheme.primary),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'Chưa có cuộc hẹn nào 🌟',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy tạo cuộc hẹn đầu tiên hoặc\ntham gia CLB để bắt đầu!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MeetupCard extends StatelessWidget {
  final Map<String, dynamic> meetup;
  const _MeetupCard({required this.meetup});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to meetup detail
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meetup['title'] ?? 'Cuộc hẹn',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  _StatusChip(status: meetup['status'] ?? 'open'),
                ],
              ),
              if (meetup['description'] != null && meetup['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  meetup['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
              const SizedBox(height: 12),

              // Location
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      meetup['place_name'] ?? '',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Time & Members
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppTheme.secondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(meetup['start_time']),
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  const Icon(Icons.people_outline, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${meetup['current_count'] ?? 0}/${meetup['max_members'] ?? 0}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              // Tags
              if (meetup['tags'] != null && (meetup['tags'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (meetup['tags'] as List).take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(fontSize: 11, color: AppTheme.primary),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    try {
      final dt = DateTime.parse(time.toString());
      return '${dt.day}/${dt.month} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'open' => (AppTheme.success, 'Mở'),
      'full' => (AppTheme.warning, 'Đầy'),
      'ongoing' => (AppTheme.secondary, 'Đang diễn ra'),
      'completed' => (AppTheme.textMuted, 'Đã xong'),
      _ => (AppTheme.textMuted, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
