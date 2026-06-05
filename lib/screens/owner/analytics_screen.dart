import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран аналитики для владельцев чайханы
class AnalyticsScreen extends StatefulWidget {
  final String choyxonaId;
  final String choyxonaName;

  const AnalyticsScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      // Все бронирования чайханы
      final allBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .get();

      // Бронирования за этот месяц
      final monthBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      // Бронирования за эту неделю
      final weekBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();

      // Подтверждённые бронирования
      int confirmedCount = 0;
      int cancelledCount = 0;
      int totalGuests = 0;
      Map<String, int> bookingsByDay = {};
      Map<String, int> bookingsByHour = {};

      for (final doc in allBookings.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final guests = (data['guests'] as num?)?.toInt() ?? 0;
        final dateStr = data['date'] as String? ?? '';
        final timeStr = data['time'] as String? ?? '';

        if (status == 'confirmed' || status == 'completed') {
          confirmedCount++;
          totalGuests += guests;
        } else if (status == 'cancelled') {
          cancelledCount++;
        }

        // Статистика по дням недели
        if (dateStr.isNotEmpty) {
          try {
            final date = DateFormat('dd.MM.yyyy').parse(dateStr);
            final dayName = DateFormat('EEEE', 'ru').format(date);
            bookingsByDay[dayName] = (bookingsByDay[dayName] ?? 0) + 1;
          } catch (_) {}
        }

        // Статистика по часам
        if (timeStr.isNotEmpty) {
          final hour = timeStr.split(':').first;
          bookingsByHour[hour] = (bookingsByHour[hour] ?? 0) + 1;
        }
      }

      // Отзывы
      final reviews = await FirebaseFirestore.instance
          .collection('reviews')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .get();

      double avgRating = 0;
      if (reviews.docs.isNotEmpty) {
        final sum = reviews.docs.fold<double>(0, (sum, doc) {
          final rating = (doc.data()['rating'] as num?)?.toDouble() ?? 0;
          return sum + rating;
        });
        avgRating = sum / reviews.docs.length;
      }

      // Самый популярный день
      String popularDay = '-';
      int maxBookings = 0;
      bookingsByDay.forEach((day, count) {
        if (count > maxBookings) {
          maxBookings = count;
          popularDay = day;
        }
      });

      // Самое популярное время
      String popularHour = '-';
      int maxHourBookings = 0;
      bookingsByHour.forEach((hour, count) {
        if (count > maxHourBookings) {
          maxHourBookings = count;
          popularHour = '$hour:00';
        }
      });

      setState(() {
        _stats = {
          'totalBookings': allBookings.docs.length,
          'monthBookings': monthBookings.docs.length,
          'weekBookings': weekBookings.docs.length,
          'confirmedBookings': confirmedCount,
          'cancelledBookings': cancelledCount,
          'totalGuests': totalGuests,
          'avgRating': avgRating,
          'reviewsCount': reviews.docs.length,
          'popularDay': popularDay,
          'popularHour': popularHour,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('analytics'.tr()),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadStatistics();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Text(
                      widget.choyxonaName,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Основные карточки
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.calendar_today,
                            title: 'За всё время',
                            value: '${_stats['totalBookings'] ?? 0}',
                            subtitle: 'бронирований',
                            color: Theme.of(context).primaryColor,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star,
                            title: 'Рейтинг',
                            value: (_stats['avgRating'] as double? ?? 0).toStringAsFixed(1),
                            subtitle: '${_stats['reviewsCount'] ?? 0} отзывов',
                            color: AppColors.starGold,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.date_range,
                            title: 'Этот месяц',
                            value: '${_stats['monthBookings'] ?? 0}',
                            subtitle: 'бронирований',
                            color: AppColors.success,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.today,
                            title: 'Эта неделя',
                            value: '${_stats['weekBookings'] ?? 0}',
                            subtitle: 'бронирований',
                            color: AppColors.info,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Детальная статистика
                    _buildSectionTitle('Детальная статистика', isDark),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      icon: Icons.check_circle,
                      label: 'Подтверждённых бронирований',
                      value: '${_stats['confirmedBookings'] ?? 0}',
                      color: AppColors.success,
                      isDark: isDark,
                    ),
                    _buildInfoRow(
                      icon: Icons.cancel,
                      label: 'Отменённых бронирований',
                      value: '${_stats['cancelledBookings'] ?? 0}',
                      color: AppColors.error,
                      isDark: isDark,
                    ),
                    _buildInfoRow(
                      icon: Icons.people,
                      label: 'Всего гостей',
                      value: '${_stats['totalGuests'] ?? 0}',
                      color: Theme.of(context).primaryColor,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    // Популярное время
                    _buildSectionTitle('Популярное время', isDark),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.wb_sunny,
                            title: 'Популярный день',
                            value: _stats['popularDay'] ?? '-',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.access_time,
                            title: 'Популярное время',
                            value: _stats['popularHour'] ?? '-',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
