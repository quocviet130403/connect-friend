import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class ClubDetailScreen extends StatefulWidget {
  final String clubId;
  const ClubDetailScreen({super.key, required this.clubId});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _club;
  List<dynamic> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.getClub(widget.clubId),
        _api.getClubMembers(widget.clubId),
      ]);
      setState(() {
        _club = results[0]['data'] as Map<String, dynamic>?;
        _members = (results[1]['data'] as List?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_club?['name'] ?? 'Câu lạc bộ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(child: Text(_club?['icon_emoji'] ?? '🎯', style: const TextStyle(fontSize: 32))),
                          ),
                          const SizedBox(height: 12),
                          Text(_club?['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (_club?['description'] != null)
                            Text(_club!['description'], style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _InfoChip(icon: Icons.people, label: '${_club?['member_count'] ?? 0} thành viên'),
                              const SizedBox(width: 12),
                              _InfoChip(icon: Icons.category, label: _club?['category'] ?? ''),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await _api.joinClub(widget.clubId);
                                  _loadData();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã tham gia CLB! 🎉'), backgroundColor: AppTheme.success),
                                    );
                                  }
                                } on ApiException catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.message), backgroundColor: AppTheme.error),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.group_add),
                              label: const Text('Tham gia CLB'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 24),
                  const Text('Thành viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  ...List.generate(
                    _members.length,
                    (i) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                        child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primary)),
                      ),
                      title: Text(_members[i]['role'] ?? 'member'),
                      subtitle: Text('ID: ${_members[i]['user_id'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
