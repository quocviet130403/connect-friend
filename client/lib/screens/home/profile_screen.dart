import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getMyProfile();
      setState(() {
        _profile = res['data'] as Map<String, dynamic>?;
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
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              _getInitial(),
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.bg, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 16),
                    Text(
                      _profile?['display_name'] ?? 'Chưa cập nhật',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    if (_profile?['bio'] != null && _profile!['bio'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(_profile!['bio'], style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                    if (_profile?['city'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Text(
                            _profile?['city']?['name'] ?? '',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Edit profile button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showEditDialog,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Chỉnh sửa hồ sơ'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Interests
                    if (_profile?['interests'] != null && (_profile!['interests'] as List).isNotEmpty) ...[
                      _buildSection('Sở thích', Icons.favorite_outline),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (_profile!['interests'] as List).map((i) => Chip(
                          label: Text(i.toString()),
                          avatar: const Icon(Icons.tag, size: 16),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Vibes
                    if (_profile?['vibes'] != null && (_profile!['vibes'] as List).isNotEmpty) ...[
                      _buildSection('Vibes', Icons.mood),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (_profile!['vibes'] as List).map((v) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary.withValues(alpha: 0.08), AppTheme.secondary.withValues(alpha: 0.08)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                          ),
                          child: Text(v.toString(), style: const TextStyle(fontSize: 13)),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Divider(),
                    const SizedBox(height: 16),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(Icons.logout, color: AppTheme.error),
                        label: const Text('Đăng xuất', style: TextStyle(color: AppTheme.error)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }

  String _getInitial() {
    final name = _profile?['display_name'] ?? '';
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _profile?['display_name'] ?? '');
    final bioCtrl = TextEditingController(text: _profile?['bio'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg,
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
            const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên hiển thị', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: bioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.edit_note))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _api.updateProfile({
                  'display_name': nameCtrl.text.trim(),
                  'bio': bioCtrl.text.trim(),
                  'city_name': 'Ho Chi Minh',
                  'city_slug': 'ho-chi-minh',
                  'interests': _profile?['interests'] ?? [],
                  'vibes': _profile?['vibes'] ?? [],
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadProfile();
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
