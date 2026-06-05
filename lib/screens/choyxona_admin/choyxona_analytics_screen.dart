import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран аналитики чайханы для админа
class ChoyxonaAnalyticsScreen extends StatefulWidget {
  final String choyxonaId;
  final String choyxonaName;
  final bool embedded;

  const ChoyxonaAnalyticsScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaName,
    this.embedded = false,
  });

  @override
  State<ChoyxonaAnalyticsScreen> createState() => _ChoyxonaAnalyticsScreenState();
}

class _ChoyxonaAnalyticsScreenState extends State<ChoyxonaAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
      }

      // Все бронирования
      final allBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .get();

      // Статистика по статусам
      int confirmed = 0, cancelled = 0, completed = 0, pending = 0;
      int totalGuests = 0;
      Map<String, int> bookingsByDay = {};
      Map<int, int> bookingsByHour = {};

      for (final doc in allBookings.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final guests = (data['guests'] as num?)?.toInt() ?? 0;
        final dateStr = data['date'] ?? '';
        final timeStr = data['time'] ?? '';

        switch (status) {
          case 'confirmed':
            confirmed++;
            break;
          case 'cancelled':
            cancelled++;
            break;
          case 'completed':
            completed++;
            totalGuests += guests;
            break;
          default:
            pending++;
        }

        // По дням недели
        if (dateStr.isNotEmpty) {
          try {
            final date = DateFormat('dd.MM.yyyy').parse(dateStr);
            final dayName = DateFormat('EEEE', 'ru').format(date);
            bookingsByDay[dayName] = (bookingsByDay[dayName] ?? 0) + 1;
          } catch (_) {}
        }

        // По часам
        if (timeStr.isNotEmpty) {
          final hour = int.tryParse(timeStr.split(':').first) ?? 0;
          bookingsByHour[hour] = (bookingsByHour[hour] ?? 0) + 1;
        }
      }

      // Отзывы
      final reviews = await FirebaseFirestore.instance
          .collection('reviews')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .get();

      double avgRating = 0;
      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      
      if (reviews.docs.isNotEmpty) {
        double sum = 0;
        for (final doc in reviews.docs) {
          final rating = ((doc.data()['rating'] as num?)?.toDouble() ?? 0).round();
          sum += rating;
          if (rating >= 1 && rating <= 5) {
            ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
          }
        }
        avgRating = sum / reviews.docs.length;
      }

      // Популярное время
      String popularTime = '-';
      int maxHour = 0;
      bookingsByHour.forEach((hour, count) {
        if (count > maxHour) {
          maxHour = count;
          popularTime = '$hour:00';
        }
      });

      // Популярный день
      String popularDay = '-';
      int maxDay = 0;
      bookingsByDay.forEach((day, count) {
        if (count > maxDay) {
          maxDay = count;
          popularDay = day;
        }
      });

      setState(() {
        _stats = {
          'totalBookings': allBookings.docs.length,
          'confirmed': confirmed,
          'cancelled': cancelled,
          'completed': completed,
          'pending': pending,
          'totalGuests': totalGuests,
          'avgRating': avgRating,
          'reviewsCount': reviews.docs.length,
          'popularTime': popularTime,
          'popularDay': popularDay,
          'ratingDistribution': ratingDistribution,
          'bookingsByHour': bookingsByHour,
          'conversionRate': allBookings.docs.isNotEmpty
              ? ((completed + confirmed) / allBookings.docs.length * 100)
              : 0.0,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Период
                _buildPeriodSelector(isDark),
                const SizedBox(height: 24),

                // Основные метрики
                _buildMainMetrics(isDark),
                const SizedBox(height: 24),

                // Круговая диаграмма статусов
                Text(
                  'booking_statuses'.tr(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusPieChart(isDark),
                const SizedBox(height: 24),

                // График бронирований по часам
                Text(
                  'bookings_by_hour'.tr(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHourlyChart(isDark),
                const SizedBox(height: 24),

                // Популярное время
                Text(
                  'popular_periods'.tr(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildInfoCard('popular_day'.tr(), _stats['popularDay'] ?? '-', Icons.calendar_today, isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInfoCard('popular_time'.tr(), _stats['popularTime'] ?? '-', Icons.access_time, isDark)),
                  ],
                ),
              ],
            ),
          );

    // Agar embedded bo'lsa, faqat body qaytariladi
    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('analytics'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAnalytics();
            },
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildStatusPieChart(bool isDark) {
    final pending = (_stats['pending'] ?? 0) as int;
    final confirmed = (_stats['confirmed'] ?? 0) as int;
    final completed = (_stats['completed'] ?? 0) as int;
    final cancelled = (_stats['cancelled'] ?? 0) as int;
    final total = pending + confirmed + completed + cancelled;

    if (total == 0) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'no_data'.tr(),
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Круговая диаграмма
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  if (pending > 0)
                    PieChartSectionData(
                      value: pending.toDouble(),
                      color: AppColors.warning,
                      title: '$pending',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      radius: 50,
                    ),
                  if (confirmed > 0)
                    PieChartSectionData(
                      value: confirmed.toDouble(),
                      color: AppColors.success,
                      title: '$confirmed',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      radius: 50,
                    ),
                  if (completed > 0)
                    PieChartSectionData(
                      value: completed.toDouble(),
                      color: AppColors.info,
                      title: '$completed',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      radius: 50,
                    ),
                  if (cancelled > 0)
                    PieChartSectionData(
                      value: cancelled.toDouble(),
                      color: AppColors.error,
                      title: '$cancelled',
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      radius: 50,
                    ),
                ],
              ),
            ),
          ),
          // Легенда
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem('pending'.tr(), AppColors.warning, pending),
                const SizedBox(height: 8),
                _buildLegendItem('confirmed'.tr(), AppColors.success, confirmed),
                const SizedBox(height: 8),
                _buildLegendItem('completed'.tr(), AppColors.info, completed),
                const SizedBox(height: 8),
                _buildLegendItem('cancelled'.tr(), AppColors.error, cancelled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyChart(bool isDark) {
    final bookingsByHour = _stats['bookingsByHour'] as Map<int, int>? ?? {};
    
    if (bookingsByHour.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'no_data'.tr(),
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
        ),
      );
    }

    // Подготавливаем данные для графика (только часы с данными)
    final sortedHours = bookingsByHour.keys.toList()..sort();
    final maxValue = bookingsByHour.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue + 1,
          barGroups: sortedHours.map((hour) {
            return BarChartGroupData(
              x: hour,
              barRods: [
                BarChartRodData(
                  toY: bookingsByHour[hour]!.toDouble(),
                  color: Theme.of(context).primaryColor,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${value.toInt()}:00',
                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPeriodChip('week'.tr(), 'week'),
          _buildPeriodChip('month'.tr(), 'month'),
          _buildPeriodChip('year'.tr(), 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedPeriod = value;
            _isLoading = true;
          });
          _loadAnalytics();
        },
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
      ),
    );
  }

  Widget _buildMainMetrics(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn('${_stats['totalBookings'] ?? 0}', 'total'.tr()),
              Container(width: 1, height: 50, color: Colors.white24),
              _buildMetricColumn('${_stats['totalGuests'] ?? 0}', 'guests'.tr()),
              Container(width: 1, height: 50, color: Colors.white24),
              _buildMetricColumn('${(_stats['conversionRate'] ?? 0).toStringAsFixed(0)}%', 'conversion'.tr()),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${'rating'.tr()}: ${(_stats['avgRating'] ?? 0).toStringAsFixed(1)} (${_stats['reviewsCount'] ?? 0} ${'reviews'.tr()})',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
