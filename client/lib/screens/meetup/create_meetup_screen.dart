import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class CreateMeetupScreen extends StatefulWidget {
  const CreateMeetupScreen({super.key});

  @override
  State<CreateMeetupScreen> createState() => _CreateMeetupScreenState();
}

class _CreateMeetupScreenState extends State<CreateMeetupScreen> {
  final _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _placeNameCtrl = TextEditingController();
  final _placeAddrCtrl = TextEditingController();
  int _maxMembers = 5;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo cuộc hẹn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề cuộc hẹn *',
                hintText: 'VD: Cafe & Chụp hình chiều nay',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Chia sẻ chi tiết về cuộc hẹn...',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _placeNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên địa điểm *',
                hintText: 'VD: Cộng Cà Phê',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _placeAddrCtrl,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                hintText: 'VD: 26 Lý Tự Trọng, Q.1',
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 20),

            // Date picker
            ListTile(
              tileColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderDark),
              ),
              leading: const Icon(Icons.calendar_today, color: AppTheme.secondary),
              title: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              subtitle: const Text('Ngày hẹn'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            const SizedBox(height: 12),

            // Time picker
            ListTile(
              tileColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderDark),
              ),
              leading: const Icon(Icons.access_time, color: AppTheme.accent),
              title: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
              subtitle: const Text('Giờ hẹn'),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                if (picked != null) setState(() => _selectedTime = picked);
              },
            ),
            const SizedBox(height: 20),

            // Max members
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, color: AppTheme.primaryLight, size: 20),
                      const SizedBox(width: 8),
                      const Text('Số người tối đa', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('$_maxMembers', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                  Slider(
                    value: _maxMembers.toDouble(),
                    min: 2,
                    max: 50,
                    divisions: 48,
                    activeColor: AppTheme.primary,
                    label: '$_maxMembers',
                    onChanged: (v) => setState(() => _maxMembers = v.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.rocket_launch),
                label: const Text('Tạo cuộc hẹn'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _placeNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền tiêu đề và địa điểm'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final startTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    try {
      await _api.createMeetup({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'place_name': _placeNameCtrl.text.trim(),
        'place_address': _placeAddrCtrl.text.trim(),
        'longitude': 106.6297, // Default HCM
        'latitude': 10.8231,
        'start_time': startTime.toUtc().toIso8601String(),
        'max_members': _maxMembers,
        'tags': [],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo cuộc hẹn! 🎉'), backgroundColor: AppTheme.success),
        );
        context.go('/meetups');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _placeNameCtrl.dispose();
    _placeAddrCtrl.dispose();
    super.dispose();
  }
}
