import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран списка бронирований для владельца
class BookingsListScreen extends StatelessWidget {
  const BookingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('bookings'.tr()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 64, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text('no_bookings'.tr(),
                      style: AppTextStyles.bodyLarge),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp?)?.toDate();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['choyxonaName'] ?? 'Чайхана',
                            style: AppTextStyles.titleMedium,
                          ),
                          _buildStatusBadge(data['status'] ?? 'pending'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(data['userName'] ?? 'Гость',
                              style: AppTextStyles.bodySmall),
                          const SizedBox(width: 16),
                          Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${data['guestCount'] ?? 0} гостей',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            date != null 
                                ? DateFormat('dd.MM.yyyy').format(date)
                                : 'Дата не указана',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(data['time'] ?? '--:--',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'confirmed':
        color = AppColors.success;
        text = 'Подтверждено';
        break;
      case 'cancelled':
        color = AppColors.error;
        text = 'Отменено';
        break;
      case 'completed':
        color = AppColors.info;
        text = 'Завершено';
        break;
      default:
        color = AppColors.accent;
        text = 'Ожидает';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}
