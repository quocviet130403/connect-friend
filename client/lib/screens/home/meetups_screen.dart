import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class MeetupsScreen extends StatefulWidget {
  const MeetupsScreen({super.key});

  @override
  State<MeetupsScreen> createState() => _MeetupsScreenState();
}

class _MeetupsScreenState extends State<MeetupsScreen> {
  final _api = ApiService();
  List<dynamic> _meetups = [];
  List<dynamic> _invites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getMeetups(),
        _api.getPendingInvites(),
      ]);
      setState(() {
        _meetups = (results[0]['data'] as List?) ?? [];
        _invites = (results[1]['data'] as List?) ?? [];
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
        title: const Text('Cuộc hẹn'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Pending invites section
                  if (_invites.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.mail, size: 18, color: AppTheme.accent),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lời mời (${_invites.length})',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _InviteCard(
                          invite: _invites[index] as Map<String, dynamic>,
                          onAccept: () => _handleInvite(_invites[index]['id'], true),
                          onDecline: () => _handleInvite(_invites[index]['id'], false),
                        ).animate().slideX(begin: 0.1, delay: Duration(milliseconds: index * 80)).fadeIn(),
                        childCount: _invites.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: Divider(indent: 16, endIndent: 16)),
                  ],

                  // Meetups list
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: const Text('Tất cả cuộc hẹn', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                  _meetups.isEmpty
                      ? SliverFillRemaining(child: _buildEmpty())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final meetup = _meetups[index] as Map<String, dynamic>;
                              return _MeetupListTile(meetup: meetup)
                                  .animate()
                                  .fadeIn(delay: Duration(milliseconds: index * 60));
                            },
                            childCount: _meetups.length,
                          ),
                        ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/meetups/create');
          if (result == true) _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo cuộc hẹn'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_outlined, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text('Chưa có cuộc hẹn', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => context.go('/meetups/create'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tạo cuộc hẹn đầu tiên'),
          ),
        ],
      ),
    );
  }

  void _handleInvite(String id, bool accept) async {
    try {
      if (accept) {
        await _api.acceptInvite(id);
      } else {
        await _api.declineInvite(id);
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}

class _InviteCard extends StatelessWidget {
  final Map<String, dynamic> invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _InviteCard({required this.invite, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event, color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Bạn được mời tham gia cuộc hẹn', style: TextStyle(fontSize: 14)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
              onPressed: onDecline,
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: const Text('Tham gia', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetupListTile extends StatelessWidget {
  final Map<String, dynamic> meetup;
  const _MeetupListTile({required this.meetup});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.event, color: AppTheme.primary),
      ),
      title: Text(meetup['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '📍 ${meetup['place_name'] ?? ''} • ${meetup['current_count'] ?? 0}/${meetup['max_members'] ?? 0} người',
        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      onTap: () => context.go('/meetups/${meetup['id']}'),
    );
  }
}
