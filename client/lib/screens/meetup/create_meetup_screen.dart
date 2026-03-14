import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

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
  bool _isLoadingLocation = false;
  double? _longitude;
  double? _latitude;

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
            const SizedBox(height: 20),

            // =================== LOCATION SECTION ===================
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
                      const Icon(Icons.location_on, color: AppTheme.accent, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Địa điểm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      // GPS button
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingLocation ? null : _pickLocationFromGPS,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.my_location, size: 16),
                          label: Text(
                            _isLoadingLocation ? 'Đang định vị...' : 'Vị trí hiện tại',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Show GPS result
                  if (_latitude != null && _longitude != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.success, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '📍 ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.success),
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextField(
                    controller: _placeNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên địa điểm *',
                      hintText: 'VD: Cộng Cà Phê',
                      prefixIcon: Icon(Icons.storefront),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _placeAddrCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ',
                      hintText: 'VD: 26 Lý Tự Trọng, Q.1',
                      prefixIcon: Icon(Icons.map),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

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

  void _pickLocationFromGPS() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await LocationService.getCurrentPosition();

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lấy vị trí. Hãy bật định vị và cho phép quyền truy cập.'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Reverse geocode to get address
      final address = await LocationService.reverseGeocode(position.latitude, position.longitude);

      if (address != null && mounted) {
        setState(() {
          if (_placeAddrCtrl.text.isEmpty) {
            _placeAddrCtrl.text = address['short_address'] ?? address['display_name'] ?? '';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Đã xác định vị trí: ${address['short_address'] ?? 'OK'}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _placeNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền tiêu đề và tên địa điểm'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy bấm "Vị trí hiện tại" để xác định tọa độ'), backgroundColor: AppTheme.warning),
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
        'longitude': _longitude,
        'latitude': _latitude,
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
