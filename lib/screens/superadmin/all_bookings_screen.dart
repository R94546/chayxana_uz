import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран всех бронирований (Super Admin)
class AllBookingsScreen extends StatefulWidget {
  const AllBookingsScreen({super.key});

  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen> {
  String _filterStatus = 'all';
  String? _filterChoyxonaId;
  DateTime? _filterDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Все бронирования'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Все')),
              const PopupMenuItem(value: 'pending', child: Text('Ожидают')),
              const PopupMenuItem(value: 'confirmed', child: Text('Подтверждённые')),
              const PopupMenuItem(value: 'completed', child: Text('Завершённые')),
              const PopupMenuItem(value: 'cancelled', child: Text('Отменённые')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры
          if (_filterDate != null || _filterChoyxonaId != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  if (_filterDate != null)
                    Chip(
                      label: Text(DateFormat('dd.MM.yyyy').format(_filterDate!)),
                      onDeleted: () => setState(() => _filterDate = null),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _filterDate = null;
                      _filterChoyxonaId = null;
                      _filterStatus = 'all';
                    }),
                    child: const Text('Сбросить'),
                  ),
                ],
              ),
            ),

          // Список
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getBookingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                final bookings = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final data = bookings[index].data() as Map<String, dynamic>;
                    return _buildBookingCard(bookings[index].id, data, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getBookingsStream() {
    var query = FirebaseFirestore.instance
        .collection('bookings')
        .orderBy('createdAt', descending: true);

    if (_filterStatus != 'all') {
      query = query.where('status', isEqualTo: _filterStatus);
    }

    return query.limit(100).snapshots();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _filterDate = picked);
    }
  }

  Widget _buildBookingCard(String id, Map<String, dynamic> data, bool isDark) {
    final status = data['status'] ?? 'pending';
    final date = data['date'] ?? '';
    final time = data['time'] ?? '';
    final guests = data['guests'] ?? 0;
    final choyxonaId = data['choyxonaId'] ?? '';
    final userId = data['userId'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название чайханы
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('choyxonas')
                            .doc(choyxonaId)
                            .get(),
                        builder: (context, snapshot) {
                          final name = snapshot.data?.get('name') ?? 'Чайхана';
                          return Text(
                            name,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          );
                        },
                      ),
                      // Имя клиента
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (context, snapshot) {
                          final firstName = snapshot.data?.get('firstName') ?? '';
                          final lastName = snapshot.data?.get('lastName') ?? '';
                          return Text(
                            '$firstName $lastName',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          );
                        },
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

            // Информация
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(Icons.calendar_today, date, isDark),
                _buildInfoItem(Icons.access_time, time, isDark),
                _buildInfoItem(Icons.people, '$guests гостей', isDark),
              ],
            ),

            const SizedBox(height: 12),

            // Действия
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'pending') ...[
                  TextButton(
                    onPressed: () => _updateStatus(id, 'cancelled'),
                    child: const Text('Отклонить', style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _updateStatus(id, 'confirmed'),
                    child: const Text('Подтвердить'),
                  ),
                ],
                if (status == 'confirmed')
                  ElevatedButton(
                    onPressed: () => _updateStatus(id, 'completed'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text('Завершить'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 11,
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Подтверждено';
      case 'cancelled':
        return 'Отменено';
      case 'completed':
        return 'Завершено';
      default:
        return 'Ожидает';
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(id)
        .update({'status': status});
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text('Нет бронирований', style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }
}
