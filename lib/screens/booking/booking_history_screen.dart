import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../models/choyxona_model.dart';
import '../reviews/rating_dialog.dart';
import 'menu_order_screen.dart';

/// Экран истории бронирований
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _selectedFilter = 'all'; // 'all', 'confirmed', 'completed'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('booking_history'.tr()),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', 'Barchasi', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('confirmed', 'Tasdiqlangan', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Tugatilgan', isDark),
              ],
            ),
          ),
          
          // Bookings list
          Expanded(
            child: FutureBuilder<String?>(
              future: _getCurrentUserId(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: userSnapshot.data)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '${'error'.tr()}: ${snapshot.error}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    // Auto-complete expired bookings
                    _autoCompleteExpiredBookings(snapshot.data!.docs);

                    // Filter bookings
                    var bookings = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] as String? ?? '';
                      
                      if (_selectedFilter == 'all') return true;
                      return status == _selectedFilter;
                    }).toList();

                    // Sort locally by createdAt descending (newest first)
                    bookings.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aTime = aData['createdAt'] as Timestamp?;
                      final bTime = bData['createdAt'] as Timestamp?;
                      if (aTime == null || bTime == null) return 0;
                      return bTime.compareTo(aTime); // descending
                    });

                    if (bookings.isEmpty) {
                      return _buildEmptyFilterState(context);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final data = booking.data() as Map<String, dynamic>;
                        return _BookingCard(
                          bookingId: booking.id,
                          data: data,
                          onDelete: data['status'] == 'completed' || data['status'] == 'cancelled'
                              ? () => _deleteBooking(booking.id)
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : (isDark ? AppColors.darkSurface : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : (isDark ? AppColors.darkCardBorder : Colors.grey.shade300),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bronni o\'chirish'),
        content: const Text('Haqiqatan ham bu bronni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('O\'chirish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bron o\'chirildi'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xatolik: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Widget _buildEmptyFilterState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Bu filtorda bronlar yo\'q',
            style: AppTextStyles.titleMedium.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Eskirgan bronlarni avtomatik "completed" qilish
  void _autoCompleteExpiredBookings(List<QueryDocumentSnapshot> docs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      final bookingDate = data['bookingDate'] as String? ?? '';
      
      // Faqat "confirmed" yoki "pending" statusli bronlarni tekshirish
      if (status != 'confirmed' && status != 'pending') continue;
      
      try {
        final date = DateTime.parse(bookingDate);
        final bookingDay = DateTime(date.year, date.month, date.day);
        
        // Agar bron sanasi o'tgan bo'lsa, "completed" qilish
        if (bookingDay.isBefore(today)) {
          FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {
        // Parsing xatosi - o'tkazish
      }
    }
  }

  Future<String?> _getCurrentUserId() async {
    final user = await AuthService().getCurrentUserData();
    return user?.userId;
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_bookings'.tr(),
              style: AppTextStyles.headlineMedium.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'book_table_favorite'.tr(),
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('find_choyxona'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка бронирования
class _BookingCard extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> data;
  final VoidCallback? onDelete;

  const _BookingCard({
    required this.bookingId,
    required this.data,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = data['status'] ?? 'pending';
    final bookingDate = data['bookingDate'] ?? '';
    final bookingTime = data['bookingTime'] ?? '';
    final guestCount = data['guestCount'] ?? 0;
    final choyxonaId = data['choyxonaId'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadow : AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Заголовок с чайханой
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('choyxonas')
                .doc(choyxonaId)
                .get(),
            builder: (context, choyxonaSnapshot) {
              String choyxonaName = 'Choyxona';
              if (choyxonaSnapshot.hasData && choyxonaSnapshot.data!.exists) {
                final docData = choyxonaSnapshot.data!.data() as Map<String, dynamic>?;
                choyxonaName = docData?['name'] as String? ?? 'Choyxona';
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _getStatusGradient(status),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            choyxonaName,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusLabel(context, status),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textWhite.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _getStatusIcon(status),
                  ],
                ),
              );
            },
          ),

          // Детали бронирования
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  Icons.calendar_today,
                  'date'.tr(),
                  _formatDate(context, bookingDate),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.access_time,
                  'time'.tr(),
                  _getTimeSlotText(data['timeSlot']),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.people,
                  'guests'.tr(),
                  guestCount.toString(),
                ),
                if (data['specialRequests']?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.note,
                    'special_requests'.tr(),
                    data['specialRequests'],
                  ),
                ],

                // Кнопки действий для подтверждённых бронирований
                if (status == 'confirmed') ...[
                  const SizedBox(height: 16),
                  // TAOM BUYURTMA TUGMASI
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMenuOrder(context),
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('🍽️ Taom buyurtma qilish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelBooking(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: Text('cancel'.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _viewDetails(context),
                          child: Text('details'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],

                // Tugmalar для completed (baholash)
                if (status == 'completed' && !(data['isRated'] == true)) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openRatingDialog(context),
                      icon: const Icon(Icons.star, color: Colors.amber),
                      label: const Text('⭐ Xizmatni baholang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],

                // Agar baholangan bo'lsa
                if (status == 'completed' && data['isRated'] == true) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        SizedBox(width: 8),
                        Text('Baholangan ✓', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],

                // O'chirish tugmasi (completed yoki cancelled uchun)
                if (onDelete != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Bronni o\'chirish'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  LinearGradient _getStatusGradient(String status) {
    switch (status) {
      case 'confirmed':
        return const LinearGradient(
          colors: [AppColors.success, Color(0xFF059669)],
        );
      case 'cancelled':
        return const LinearGradient(
          colors: [AppColors.error, Color(0xFFDC2626)],
        );
      case 'completed':
        return const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A5F7A)],
        );
      default:
        return const LinearGradient(
          colors: [AppColors.warning, Color(0xFFF59E0B)],
        );
    }
  }

  String _getStatusLabel(BuildContext context, String status) {
    switch (status) {
      case 'confirmed':
        return 'status_confirmed'.tr();
      case 'cancelled':
        return 'status_cancelled'.tr();
      case 'completed':
        return 'status_completed'.tr();
      case 'no_show':
        return 'status_no_show'.tr();
      default:
        return 'status_pending'.tr();
    }
  }

  Widget _getStatusIcon(String status) {
    IconData icon;
    switch (status) {
      case 'confirmed':
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        break;
      case 'completed':
        icon = Icons.check_circle_outline;
        break;
      default:
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.textWhite.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.textWhite, size: 24),
    );
  }

  String _formatDate(BuildContext context, String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      // Use 'uz' locale for Uzbek date formatting
      final locale = context.locale.languageCode == 'uz' ? 'uz' : context.locale.languageCode;
      return DateFormat('d MMMM yyyy, EEE', locale).format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getTimeSlotText(String? timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return 'Kunduzi (08:00 - 16:00)';
      case 'evening':
        return 'Kechasi (16:00 - 00:00)';
      default:
        return 'Belgilanmagan';
    }
  }

  Future<void> _openMenuOrder(BuildContext context) async {
    try {
      final choyxonaDoc = await FirebaseFirestore.instance
          .collection('choyxonas')
          .doc(data['choyxonaId'])
          .get();
      
      if (!choyxonaDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Choyxona topilmadi'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      final choyxona = Choyxona.fromFirestore(choyxonaDoc);
      
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MenuOrderScreen(
              choyxonaId: choyxona.id,
              choyxonaName: choyxona.name,
              bookingId: bookingId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _openRatingDialog(BuildContext context) async {
    final choyxonaId = data['choyxonaId'] as String?;
    final choyxonaName = data['choyxonaName'] as String? ?? 'Choyxona';
    final userId = data['userId'] as String?;
    
    if (choyxonaId == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ma\'lumotlar topilmadi'), backgroundColor: AppColors.error),
      );
      return;
    }

    await RatingDialog.show(
      context,
      bookingId: bookingId,
      choyxonaId: choyxonaId,
      choyxonaName: choyxonaName,
      userId: userId,
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'cancel_booking_title'.tr(),
          style: AppTextStyles.titleLarge.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'cancel_booking_message'.tr(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('no'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text('yes_cancel'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': 'cancelled',
          'cancellationReason': 'cancelled_by_user'.tr(),
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('booking_cancelled'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error'.tr()}: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _viewDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'booking_details'.tr(),
              style: AppTextStyles.headlineSmall.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(context, Icons.confirmation_number, 'ID', bookingId.substring(0, 8)),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.calendar_today, 'date'.tr(), _formatDate(context, data['bookingDate'])),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.access_time, 'time'.tr(), data['bookingTime']),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.people, 'guests'.tr(), data['guestCount'].toString()),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.person, 'name'.tr(), data['guestName'] ?? '-'),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.phone, 'phone'.tr(), data['guestPhone'] ?? '-'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('close'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}