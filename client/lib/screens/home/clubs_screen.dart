import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  final _api = ApiService();
  List<dynamic> _clubs = [];
  bool _isLoading = true;
  String? _selectedCategory;

  final _categories = ['Tất cả', 'Cafe', 'Sport', 'Gaming', 'Photography', 'Music', 'Food', 'Travel', 'Study'];

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getClubs(category: _selectedCategory);
      setState(() {
        _clubs = (res['data'] as List?) ?? [];
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
        title: const Text('Câu lạc bộ'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = (_selectedCategory == null && index == 0) ||
                    _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = index == 0 ? null : cat;
                      });
                      _loadClubs();
                    },
                    selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Club list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadClubs,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _clubs.isEmpty
                      ? _buildEmpty()
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _clubs.length,
                          itemBuilder: (context, index) {
                            final club = _clubs[index] as Map<String, dynamic>;
                            return _ClubCard(club: club).animate()
                                .scale(begin: const Offset(0.9, 0.9), delay: Duration(milliseconds: index * 60))
                                .fadeIn();
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Create club dialog
          _showCreateClubDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo CLB'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_outlined, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text('Chưa có câu lạc bộ nào', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showCreateClubDialog,
            child: const Text('Tạo CLB đầu tiên'),
          ),
        ],
      ),
    );
  }

  void _showCreateClubDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Cafe';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tạo Câu Lạc Bộ ✨', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tối đa 3 CLB / người', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên CLB', prefixIcon: Icon(Icons.group))),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Mô tả', prefixIcon: Icon(Icons.description))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
              items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => category = v!,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  await _api.createClub({
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'category': category,
                    'city_name': 'Ho Chi Minh',
                    'city_slug': 'ho-chi-minh',
                    'is_public': true,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadClubs();
                } on ApiException catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppTheme.error));
                  }
                }
              },
              child: const Text('Tạo CLB'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final Map<String, dynamic> club;
  const _ClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/clubs/${club['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(club['icon_emoji'] ?? '🎯', style: const TextStyle(fontSize: 24)),
                ),
              ),
              const Spacer(),
              Text(
                club['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.people, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${club['member_count'] ?? 0} thành viên',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  club['category'] ?? '',
                  style: const TextStyle(fontSize: 10, color: AppTheme.secondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
