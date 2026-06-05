import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/push_notification_service.dart';
import 'admin_add_order_screen.dart';

/// Экран бронирований для админа чайханы
class ChoyxonaBookingsScreen extends StatefulWidget {
  final String choyxonaId;

  const ChoyxonaBookingsScreen({super.key, required this.choyxonaId});

  @override
  State<ChoyxonaBookingsScreen> createState() => _ChoyxonaBookingsScreenState();
}

class _ChoyxonaBookingsScreenState extends State<ChoyxonaBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Auto-complete expired bookings
    _autoCompleteExpiredBookings();
  }

  /// Automatically mark past confirmed bookings as completed
  Future<void> _autoCompleteExpiredBookings() async {
    try {
      final today = DateTime.now();
      final todayString = DateFormat('yyyy-MM-dd').format(today);
      
      // Get confirmed bookings for this choyxona
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .where('status', isEqualTo: 'confirmed')
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      int updatedCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final bookingDate = data['bookingDate'] as String? ?? '';
        
        // If booking date is before today, mark as completed
        if (bookingDate.isNotEmpty && bookingDate.compareTo(todayString) < 0) {
          batch.update(doc.reference, {
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
            'completedAt': FieldValue.serverTimestamp(),
            'completedBy': 'auto',
          });
          updatedCount++;
        }
      }
      
      if (updatedCount > 0) {
        await batch.commit();
        debugPrint('Auto-completed $updatedCount expired bookings');
      }
    } catch (e) {
      debugPrint('Error auto-completing bookings: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Бронирования'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Ожидают'),
            Tab(text: 'Подтверждённые'),
            Tab(text: 'Завершённые'),
            Tab(text: 'Отменённые'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList('pending'),
          _buildBookingsList('confirmed'),
          _buildBookingsList('completed'),
          _buildBookingsList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(String status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(status, isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildBookingCard(doc.id, data, status, isDark);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(String id, Map<String, dynamic> data, String status, bool isDark) {
    final date = data['bookingDate'] ?? '';
    final timeSlot = data['timeSlot'] as String? ?? '';
    final slotText = timeSlot == 'morning' ? 'Kunduzi' : timeSlot == 'evening' ? 'Kechasi' : '';
    final guests = data['guestCount'] ?? 0;
    final roomNumber = data['roomNumber'] as String?;
    final notes = data['specialRequests'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с клиентом
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['guestName']?.toString().trim().isNotEmpty == true 
                            ? data['guestName'] 
                            : 'Mehmon',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      if (data['guestPhone']?.toString().isNotEmpty == true)
                        Text(
                          data['guestPhone'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Информация о брони
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(Icons.calendar_today, date, 'Sana', isDark),
                _buildInfoItem(Icons.access_time, slotText, 'Vaqt', isDark),
                _buildInfoItem(Icons.people, '$guests', 'Mehmon', isDark),
                if (roomNumber != null)
                  _buildInfoItem(Icons.meeting_room, 'Xona $roomNumber', 'Xona', isDark),
              ],
            ),

            // Примечания
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Время создания
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Создано: ${DateFormat('dd.MM.yyyy HH:mm').format(createdAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextLight : AppColors.textLight,
                ),
              ),
            ],

            // Действия для pending
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(id, 'cancelled'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Rad etish'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(id, 'confirmed'),
                      child: const Text('Tasdiqlash'),
                    ),
                  ),
                ],
              ),
            ],

            // Действие для confirmed
            if (status == 'confirmed') ...[
              const SizedBox(height: 16),
              // Taom qo'shish tugmasi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openAddOrder(context, id, data),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('🍽️ Taom qo\'shish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(id, 'completed'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: const Text('Yakunlash'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'confirmed':
        color = AppColors.success;
        text = 'Tasdiqlangan';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'Bekor qilingan';
        break;
      case 'completed':
        color = AppColors.info;
        text = 'Yakunlangan';
        break;
      default:
        color = AppColors.warning;
        text = 'Kutilmoqda';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(String status, bool isDark) {
    String message;
    switch (status) {
      case 'pending':
        message = 'Нет ожидающих бронирований';
        break;
      case 'confirmed':
        message = 'Нет подтверждённых бронирований';
        break;
      case 'completed':
        message = 'Нет завершённых бронирований';
        break;
      default:
        message = 'Нет отменённых бронирований';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }

  void _openAddOrder(BuildContext context, String bookingId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddOrderScreen(
          bookingId: bookingId,
          choyxonaId: widget.choyxonaId,
          userId: data['userId'] ?? '',
          roomNumber: data['roomNumber'] as String?,
        ),
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      // Oldin bronni olish
      final bookingDoc = await FirebaseFirestore.instance.collection('bookings').doc(id).get();
      final bookingData = bookingDoc.data();
      
      if (bookingData == null) return;
      
      String? assignedRoomId;
      String? assignedRoomNumber;
      
      // Agar tasdiqlash bo'lsa - bo'sh xona topish
      if (status == 'confirmed') {
        final choyxonaId = bookingData['choyxonaId'] as String?;
        final bookingDate = bookingData['bookingDate'] as String?;
        final timeSlot = bookingData['timeSlot'] as String? ?? 'morning';
        
        if (choyxonaId != null && bookingDate != null) {
          // Bu kunning bronlarini olish (tasdiqlangan)
          final existingBookings = await FirebaseFirestore.instance
              .collection('bookings')
              .where('choyxonaId', isEqualTo: choyxonaId)
              .where('bookingDate', isEqualTo: bookingDate)
              .where('timeSlot', isEqualTo: timeSlot)
              .where('status', isEqualTo: 'confirmed')
              .get();
          
          // Band xonalar ro'yxati
          final bookedRoomIds = existingBookings.docs
              .map((doc) => doc.data()['roomId'] as String?)
              .where((id) => id != null)
              .toSet();
          
          // Barcha xonalarni olish
          final allRooms = await FirebaseFirestore.instance
              .collection('tables')
              .where('choyxonaId', isEqualTo: choyxonaId)
              .get();
          
          // Birinchi bo'sh xonani topish
          for (var room in allRooms.docs) {
            if (!bookedRoomIds.contains(room.id)) {
              assignedRoomId = room.id;
              assignedRoomNumber = room.data()['number']?.toString() ?? '1';
              break;
            }
          }
        }
      }
      
      // Statusni yangilash
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (assignedRoomId != null) {
        updateData['roomId'] = assignedRoomId;
        updateData['roomNumber'] = assignedRoomNumber;
      }
      
      await FirebaseFirestore.instance.collection('bookings').doc(id).update(updateData);

      // Foydalanuvchiga notification yuborish
      if (bookingData['userId'] != null) {
        final userId = bookingData['userId'] as String;
        final date = bookingData['bookingDate'] ?? '';
        final timeSlot = bookingData['timeSlot'] as String? ?? 'morning';
        final slotText = timeSlot == 'morning' ? 'Kunduzi' : 'Kechasi';
        
        String title;
        String body;
        
        if (status == 'confirmed') {
          title = 'Bron tasdiqlandi! ✅';
          body = assignedRoomNumber != null 
              ? 'Sizning $date kuni $slotText dagi broningiz tasdiqlandi. Xona raqami: $assignedRoomNumber'
              : 'Sizning $date kuni $slotText dagi broningiz tasdiqlandi.';
        } else if (status == 'cancelled') {
          title = 'Bron rad etildi ❌';
          body = 'Sizning $date kuni $slotText dagi broningiz rad etildi.';
        } else if (status == 'completed') {
          title = 'Tashrif yakunlandi 🎉';
          body = 'Tashrifingiz uchun rahmat! Iltimos, xizmatimizni baholang.';
        } else {
          title = 'Bron yangilandi';
          body = 'Broningiz statusi yangilandi.';
        }
        
        await PushNotificationService().sendNotificationToUser(
          userId: userId,
          title: title,
          body: body,
          data: {
            'type': 'booking_status_update',
            'bookingId': id,
            'status': status,
          },
        );
      }

      if (mounted) {
        final msg = status == 'confirmed'
            ? (assignedRoomNumber != null ? 'Bron tasdiqlandi. Xona: $assignedRoomNumber' : 'Bron tasdiqlandi')
            : status == 'completed'
                ? 'Bron yakunlandi'
                : 'Bron rad etildi';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: status == 'cancelled' ? AppColors.error : AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
