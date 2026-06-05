import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/choyxona_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';

/// Экран бронирования - день + слот (Kunduzi/Kechasi)
class BookingScreen extends StatefulWidget {
  final Choyxona choyxona;

  const BookingScreen({
    super.key,
    required this.choyxona,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = 'morning'; // 'morning' (08:00-16:00) yoki 'evening' (16:00-00:00)
  int _guestCount = 2;
  final TextEditingController _specialRequestsController = TextEditingController();
  bool _isLoading = false;
  bool _isDataLoading = true;
  
  int _totalRooms = 0;
  
  // Занятость по датам и слотам: {'2025-01-29': {'morning': 5, 'evening': 3}}
  Map<String, Map<String, int>> _bookedPerDateSlot = {};

  @override
  void initState() {
    super.initState();
    _loadBookingData();
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  /// Загрузить данные бронирования
  Future<void> _loadBookingData() async {
    setState(() => _isDataLoading = true);

    try {
      // Xonalar soni - faqat roomCount'dan
      _totalRooms = widget.choyxona.roomCount > 0 ? widget.choyxona.roomCount : 10;

      // Загрузить занятость на 30 дней вперёд
      final Map<String, Map<String, int>> bookedData = {};
      
      for (int i = 0; i < 30; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        
        // Бронирования на утро
        final morningBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('choyxonaId', isEqualTo: widget.choyxona.id)
            .where('bookingDate', isEqualTo: dateStr)
            .where('timeSlot', isEqualTo: 'morning')
            .where('status', whereIn: ['pending', 'confirmed'])
            .get();

        // Бронирования на вечер
        final eveningBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('choyxonaId', isEqualTo: widget.choyxona.id)
            .where('bookingDate', isEqualTo: dateStr)
            .where('timeSlot', isEqualTo: 'evening')
            .where('status', whereIn: ['pending', 'confirmed'])
            .get();

        bookedData[dateStr] = {
          'morning': morningBookings.docs.length,
          'evening': eveningBookings.docs.length,
        };
      }

      if (mounted) {
        setState(() {
          _bookedPerDateSlot = bookedData;
          _isDataLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading booking data: $e');
      if (mounted) {
        setState(() => _isDataLoading = false);
      }
    }
  }

  /// Получить количество свободных комнат для даты и слота
  int _getAvailableRooms(String dateStr, String slot) {
    final booked = _bookedPerDateSlot[dateStr]?[slot] ?? 0;
    return (_totalRooms - booked).clamp(0, _totalRooms);
  }

  /// Проверить доступность слота
  bool _isSlotAvailable(String dateStr, String slot) {
    return _getAvailableRooms(dateStr, slot) > 0;
  }

  /// Kun uchun umumiy holat
  bool _isDayFullyBooked(String dateStr) {
    return !_isSlotAvailable(dateStr, 'morning') && !_isSlotAvailable(dateStr, 'evening');
  }

  /// Получить цвет для даты в календаре
  /// 🟢 Yashil = hammasi bo'sh
  /// 🔴 Qizil = hammasi band
  /// 🟡 Sariq = kechasi band, kunduzi bo'sh
  /// ⚪ Kulrang = kunduzi band, kechasi bo'sh
  Color _getDateColor(String dateStr) {
    final morningAvailable = _isSlotAvailable(dateStr, 'morning');
    final eveningAvailable = _isSlotAvailable(dateStr, 'evening');

    if (morningAvailable && eveningAvailable) {
      return const Color(0xFF4CAF50); // Yashil - hammasi bo'sh
    } else if (!morningAvailable && !eveningAvailable) {
      return const Color(0xFFE53935); // Qizil - hammasi band
    } else if (!eveningAvailable && morningAvailable) {
      return const Color(0xFFFFB300); // Sariq - kechasi band
    } else {
      return const Color(0xFF78909C); // Kulrang - kunduzi band
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('book_table'.tr()),
        elevation: 0,
      ),
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Информация о чайхане
                  _buildChoyxonaInfo(),
                  const SizedBox(height: 24),

                  // Выбор даты
                  _buildSectionTitle('select_date'.tr()),
                  const SizedBox(height: 12),
                  _buildDateSelector(),
                  const SizedBox(height: 8),
                  _buildColorLegend(),
                  const SizedBox(height: 24),

                  // Выбор слота (Kunduzi/Kechasi)
                  _buildSectionTitle('Vaqtni tanlang'),
                  const SizedBox(height: 12),
                  _buildSlotSelector(),
                  const SizedBox(height: 24),

                  // Количество гостей
                  _buildSectionTitle('guest_count'.tr()),
                  const SizedBox(height: 12),
                  _buildGuestCountSelector(),
                  const SizedBox(height: 24),

                  // Пожелания
                  _buildSectionTitle('special_requests'.tr()),
                  const SizedBox(height: 12),
                  _buildSpecialRequestsField(),
                  const SizedBox(height: 32),

                  // Кнопка бронирования
                  _buildBookButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChoyxonaInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (widget.choyxona.images.isNotEmpty && 
                    widget.choyxona.images.first.startsWith('http'))
                ? Image.network(
                    widget.choyxona.images.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.restaurant, color: AppColors.primary),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.restaurant, color: AppColors.primary),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.choyxona.name,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.meeting_room, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalRooms ta xona mavjud',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) == dateStr;
          final dateColor = _getDateColor(dateStr);
          final isFullyBooked = _isDayFullyBooked(dateStr);
          final morningCount = _getAvailableRooms(dateStr, 'morning');
          final eveningCount = _getAvailableRooms(dateStr, 'evening');

          return GestureDetector(
            onTap: isFullyBooked ? null : () {
              setState(() {
                _selectedDate = date;
                // Avtomatik bo'sh slotni tanlash
                if (!_isSlotAvailable(dateStr, _selectedSlot)) {
                  _selectedSlot = _isSlotAvailable(dateStr, 'morning') ? 'morning' : 'evening';
                }
              });
            },
            child: Container(
              width: 75,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? dateColor : dateColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(color: dateColor, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE', 'uz').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : dateColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : dateColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isFullyBooked ? 'Band' : '${morningCount + eveningCount} bo\'sh',
                    style: TextStyle(
                      color: isSelected ? Colors.white.withValues(alpha: 0.9) : dateColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildLegendItem(const Color(0xFF4CAF50), 'Hammasi bo\'sh'),
        _buildLegendItem(const Color(0xFFFFB300), 'Kechasi band'),
        _buildLegendItem(const Color(0xFF78909C), 'Kunduzi band'),
        _buildLegendItem(const Color(0xFFE53935), 'Hammasi band'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }

  Widget _buildSlotSelector() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final morningAvailable = _isSlotAvailable(dateStr, 'morning');
    final eveningAvailable = _isSlotAvailable(dateStr, 'evening');
    final morningCount = _getAvailableRooms(dateStr, 'morning');
    final eveningCount = _getAvailableRooms(dateStr, 'evening');

    return Row(
      children: [
        // KUNDUZI
        Expanded(
          child: GestureDetector(
            onTap: morningAvailable ? () => setState(() => _selectedSlot = 'morning') : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedSlot == 'morning' && morningAvailable
                    ? AppColors.primary
                    : morningAvailable
                        ? AppColors.surface
                        : AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedSlot == 'morning' ? AppColors.primary : AppColors.border,
                  width: _selectedSlot == 'morning' ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.wb_sunny,
                    size: 32,
                    color: _selectedSlot == 'morning' && morningAvailable
                        ? Colors.white
                        : morningAvailable
                            ? const Color(0xFFFFB300)
                            : AppColors.textLight,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KUNDUZI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedSlot == 'morning' && morningAvailable
                          ? Colors.white
                          : morningAvailable
                              ? AppColors.textPrimary
                              : AppColors.textLight,
                    ),
                  ),
                  Text(
                    '08:00 - 16:00',
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedSlot == 'morning' && morningAvailable
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: morningAvailable
                          ? (_selectedSlot == 'morning' ? Colors.white.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.1))
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      morningAvailable ? '$morningCount ta bo\'sh' : 'Band',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: morningAvailable
                            ? (_selectedSlot == 'morning' ? Colors.white : AppColors.success)
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // KECHASI
        Expanded(
          child: GestureDetector(
            onTap: eveningAvailable ? () => setState(() => _selectedSlot = 'evening') : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedSlot == 'evening' && eveningAvailable
                    ? AppColors.primary
                    : eveningAvailable
                        ? AppColors.surface
                        : AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedSlot == 'evening' ? AppColors.primary : AppColors.border,
                  width: _selectedSlot == 'evening' ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.nights_stay,
                    size: 32,
                    color: _selectedSlot == 'evening' && eveningAvailable
                        ? Colors.white
                        : eveningAvailable
                            ? const Color(0xFF5C6BC0)
                            : AppColors.textLight,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KECHASI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedSlot == 'evening' && eveningAvailable
                          ? Colors.white
                          : eveningAvailable
                              ? AppColors.textPrimary
                              : AppColors.textLight,
                    ),
                  ),
                  Text(
                    '16:00 - 00:00',
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedSlot == 'evening' && eveningAvailable
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: eveningAvailable
                          ? (_selectedSlot == 'evening' ? Colors.white.withValues(alpha: 0.2) : AppColors.success.withValues(alpha: 0.1))
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      eveningAvailable ? '$eveningCount ta bo\'sh' : 'Band',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: eveningAvailable
                            ? (_selectedSlot == 'evening' ? Colors.white : AppColors.success)
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestCountSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            '$_guestCount kishi',
            style: AppTextStyles.titleMedium,
          ),
          const Spacer(),
          IconButton(
            onPressed: _guestCount > 1 ? () => setState(() => _guestCount--) : null,
            icon: Icon(
              Icons.remove_circle_outline,
              color: _guestCount > 1 ? AppColors.primary : AppColors.textLight,
            ),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              _guestCount.toString(),
              style: AppTextStyles.titleLarge,
            ),
          ),
          IconButton(
            onPressed: _guestCount < 20 ? () => setState(() => _guestCount++) : null,
            icon: Icon(
              Icons.add_circle_outline,
              color: _guestCount < 20 ? AppColors.primary : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialRequestsField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: _specialRequestsController,
      maxLines: 3,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'special_requests_placeholder'.tr(),
        hintStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
      ),
    );
  }

  Widget _buildBookButton() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isAvailable = _isSlotAvailable(dateStr, _selectedSlot);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isAvailable && !_isLoading ? _createBooking : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'confirm_booking'.tr(),
                style: AppTextStyles.button,
              ),
      ),
    );
  }

  Future<void> _createBooking() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    if (!_isSlotAvailable(dateStr, _selectedSlot)) {
      _showError('Bu vaqt uchun bo\'sh xona yo\'q');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUserData();

      if (currentUser == null) {
        _showError('not_authorized'.tr());
        setState(() => _isLoading = false);
        return;
      }

      // Создать бронирование
      final bookingData = {
        'userId': currentUser.userId,
        'choyxonaId': widget.choyxona.id,
        'choyxonaName': widget.choyxona.name,
        'bookingDate': dateStr,
        'bookingTime': null,
        'timeSlot': _selectedSlot, // 'morning' yoki 'evening'
        'duration': 480,
        'guestCount': _guestCount,
        'guestName': currentUser.fullName.isNotEmpty ? currentUser.fullName : currentUser.email,
        'guestPhone': currentUser.phone,
        'guestEmail': currentUser.email,
        'specialRequests': _specialRequestsController.text.trim(),
        'status': 'pending',
        'paymentStatus': 'unpaid',
        'paymentMethod': 'cash',
        'roomId': null,
        'roomNumber': null,
        'hasOrder': false,
        'isRated': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      // Уведомить админа
      await _notifyAdmin(currentUser, dateStr);

      if (mounted) {
        _showSuccess('booking_success'.tr());
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('error'.tr() + ': $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _notifyAdmin(dynamic user, String dateStr) async {
    try {
      final adminsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('choyxonaId', isEqualTo: widget.choyxona.id)
          .where('role', whereIn: ['choyxona_admin', 'choyxona_owner'])
          .get();

      final slotText = _selectedSlot == 'morning' ? 'Kunduzi (08:00-16:00)' : 'Kechasi (16:00-00:00)';

      for (var adminDoc in adminsSnapshot.docs) {
        final adminId = adminDoc.id;
        
        await PushNotificationService().sendNotificationToUser(
          userId: adminId,
          title: 'Yangi bron! 📅',
          body: '${user.fullName.isNotEmpty ? user.fullName : 'Mijoz'} ${widget.choyxona.name}ga $dateStr kuni $slotText uchun $_guestCount kishi bron qildi',
          data: {
            'type': 'new_booking',
            'choyxonaId': widget.choyxona.id,
          },
        );
      }
    } catch (e) {
      debugPrint('Error notifying admin: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }
}