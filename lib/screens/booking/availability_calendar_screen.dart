import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/choyxona_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'booking_screen.dart';

/// Календарь занятости - kun + Kunduzi/Kechasi
class AvailabilityCalendarScreen extends StatefulWidget {
  final Choyxona choyxona;

  const AvailabilityCalendarScreen({
    super.key,
    required this.choyxona,
  });

  @override
  State<AvailabilityCalendarScreen> createState() => _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState extends State<AvailabilityCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Бронирования: {date: {slot: count}}
  Map<String, Map<String, int>> _bookingsPerDate = {};
  bool _isLoading = true;
  int _totalRooms = 0;

  @override
  void initState() {
    super.initState();
    _totalRooms = widget.choyxona.roomCount > 0 ? widget.choyxona.roomCount : 10;
    _loadAllBookings();
  }

  Future<void> _loadAllBookings() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final Map<String, Map<String, int>> bookings = {};
      
      // 60 kunlik ma'lumot
      for (int i = 0; i < 60; i++) {
        final date = now.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        
        final snapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('choyxonaId', isEqualTo: widget.choyxona.id)
            .where('bookingDate', isEqualTo: dateStr)
            .where('status', whereIn: ['pending', 'confirmed'])
            .get();

        int morning = 0;
        int evening = 0;
        
        for (var doc in snapshot.docs) {
          final slot = doc.data()['timeSlot'] as String?;
          if (slot == 'morning') morning++;
          else if (slot == 'evening') evening++;
          else morning++; // default
        }
        
        bookings[dateStr] = {'morning': morning, 'evening': evening};
      }

      if (mounted) {
        setState(() {
          _bookingsPerDate = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _getAvailable(String dateStr, String slot) {
    final booked = _bookingsPerDate[dateStr]?[slot] ?? 0;
    return (_totalRooms - booked).clamp(0, _totalRooms);
  }

  bool _isSlotAvailable(String dateStr, String slot) {
    return _getAvailable(dateStr, slot) > 0;
  }

  bool _isDayFullyBooked(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return !_isSlotAvailable(dateStr, 'morning') && !_isSlotAvailable(dateStr, 'evening');
  }

  Color _getDayColor(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final mornAvail = _isSlotAvailable(dateStr, 'morning');
    final evenAvail = _isSlotAvailable(dateStr, 'evening');

    if (mornAvail && evenAvail) return const Color(0xFF4CAF50);
    if (!mornAvail && !evenAvail) return const Color(0xFFE53935);
    if (!evenAvail && mornAvail) return const Color(0xFFFFB300);
    return const Color(0xFF78909C);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('availability_calendar'.tr()),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Choyxona info
                  _buildChoyxonaHeader(),
                  
                  // Kalendar
                  _buildCalendar(),
                  
                  // Tanlangan kun uchun slotlar
                  _buildSelectedDaySlots(),
                  
                  // Bron tugmasi
                  _buildBookButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildChoyxonaHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.choyxona.name, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '$_totalRooms ta xona mavjud',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 60)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.monday,
      locale: context.locale.languageCode,
      onDaySelected: (selectedDay, focusedDay) {
        if (!_isDayFullyBooked(selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        }
      },
      onFormatChanged: (format) {
        setState(() => _calendarFormat = format);
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, false);
        },
        selectedBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, true);
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, isSameDay(day, _selectedDay));
        },
        disabledBuilder: (context, day, focusedDay) {
          return _buildDayCell(day, false, disabled: true);
        },
      ),
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        formatButtonDecoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        formatButtonTextStyle: const TextStyle(color: AppColors.primary),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isSelected, {bool disabled = false}) {
    final color = _getDayColor(day);
    final isFullyBooked = _isDayFullyBooked(day);
    
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? color : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: color, width: 2) : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.day.toString(),
              style: TextStyle(
                color: disabled ? AppColors.textLight : (isSelected ? Colors.white : color),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                decoration: isFullyBooked ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDaySlots() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final mornAvail = _getAvailable(dateStr, 'morning');
    final evenAvail = _getAvailable(dateStr, 'evening');
    final dayName = DateFormat('d MMMM, EEEE', 'uz').format(_selectedDay);

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dayName, style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              // KUNDUZI
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mornAvail > 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: mornAvail > 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.wb_sunny,
                        color: mornAvail > 0 ? const Color(0xFFFFB300) : AppColors.textLight,
                      ),
                      const SizedBox(height: 4),
                      Text('KUNDUZI', style: TextStyle(fontWeight: FontWeight.bold, color: mornAvail > 0 ? AppColors.textPrimary : AppColors.textLight)),
                      Text('08:00 - 16:00', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        mornAvail > 0 ? '$mornAvail ta bo\'sh' : 'Band',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: mornAvail > 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // KECHASI
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: evenAvail > 0 ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: evenAvail > 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.nights_stay,
                        color: evenAvail > 0 ? const Color(0xFF5C6BC0) : AppColors.textLight,
                      ),
                      const SizedBox(height: 4),
                      Text('KECHASI', style: TextStyle(fontWeight: FontWeight.bold, color: evenAvail > 0 ? AppColors.textPrimary : AppColors.textLight)),
                      Text('16:00 - 00:00', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        evenAvail > 0 ? '$evenAvail ta bo\'sh' : 'Band',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: evenAvail > 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ranglar izohi
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildLegend(const Color(0xFF4CAF50), 'Hammasi bo\'sh'),
              _buildLegend(const Color(0xFFFFB300), 'Kechasi band'),
              _buildLegend(const Color(0xFF78909C), 'Kunduzi band'),
              _buildLegend(const Color(0xFFE53935), 'Hammasi band'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildBookButton() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final hasAvailable = _isSlotAvailable(dateStr, 'morning') || _isSlotAvailable(dateStr, 'evening');

    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: hasAvailable ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingScreen(choyxona: widget.choyxona),
              ),
            );
          } : null,
          icon: const Icon(Icons.event_available),
          label: Text('book_table'.tr()),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
