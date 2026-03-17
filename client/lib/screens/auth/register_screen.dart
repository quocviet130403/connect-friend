import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Tạo tài khoản ✨',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fadeIn(),
              const SizedBox(height: 8),
              Text(
                'Bắt đầu kết nối với bạn bè mới',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                  prefixText: '+84 ',
                ),
              ).animate().slideX(begin: -0.1, delay: 200.ms).fadeIn(),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ).animate().slideX(begin: -0.1, delay: 300.ms).fadeIn(),
              const SizedBox(height: 16),

              TextField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
              ).animate().slideX(begin: -0.1, delay: 400.ms).fadeIn(),

              Consumer<AuthProvider>(
                builder: (context, auth, _) => auth.error != null
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                        ),
                        child: Text(auth.error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Info about device limit
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mỗi thiết bị tối đa 2 tài khoản',
                        style: TextStyle(color: AppTheme.primary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 24),

              Consumer<AuthProvider>(
                builder: (context, auth, _) => SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleRegister,
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Đăng ký'),
                  ),
                ),
              ).animate().slideY(begin: 0.2, delay: 600.ms).fadeIn(),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Đã có tài khoản? ', style: TextStyle(color: AppTheme.textSecondary)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Đăng nhập', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (phone.isEmpty || password.isEmpty) return;
    if (password != confirm) {
      context.read<AuthProvider>().clearError();
      // Show error through snackbar since it's a local validation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu không khớp'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu tối thiểu 6 ký tự'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.clearError();
    // Use a simple device ID for now
    final success = await auth.register(phone, password, 'device_${DateTime.now().millisecondsSinceEpoch}');
    if (success && mounted) {
      context.go('/explore');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
