import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/ethereal_components.dart';

/// 📊 Reports Screen with Ethereal Design
class ReportsScreen extends StatefulWidget {
  final String choyxonaId;
  final String choyxonaName;
  
  const ReportsScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTimeRange _dateRange;
  bool _isLoading = false;
  
  // Data for report
  int _totalBookings = 0;
  int _confirmedBookings = 0;
  int _cancelledBookings = 0;
  double _totalRevenue = 0;
  double _averageRating = 0;
  int _totalReviews = 0;
  
  // New: Orders data
  int _totalOrders = 0;
  int _paidOrders = 0;
  double _totalTips = 0;
  double _totalDiscount = 0;
  double _averageCheck = 0;
  Map<String, int> _topDishes = {};
  Map<String, double> _dailyRevenue = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Load bookings
      final bookingsQuery = await firestore
          .collection('bookings')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange.end))
          .get();
      
      _totalBookings = bookingsQuery.docs.length;
      _confirmedBookings = bookingsQuery.docs
          .where((doc) => doc['status'] == 'confirmed')
          .length;
      _cancelledBookings = bookingsQuery.docs
          .where((doc) => doc['status'] == 'cancelled')
          .length;
      
      // Load REAL orders revenue
      final ordersQuery = await firestore
          .collection('orders')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange.start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange.end))
          .get();
      
      _totalOrders = ordersQuery.docs.length;
      _totalRevenue = 0;
      _paidOrders = 0;
      _totalTips = 0;
      _totalDiscount = 0;
      _topDishes.clear();
      _dailyRevenue.clear();
      
      Map<String, int> dishCount = {};
      
      for (var doc in ordersQuery.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        final total = (data['total'] ?? 0).toDouble();
        final tips = (data['tips'] ?? 0).toDouble();
        final discount = (data['discount'] ?? 0).toDouble();
        
        if (status == 'paid') {
          _paidOrders++;
          _totalRevenue += total;
          _totalTips += tips;
          _totalDiscount += discount;
          
          // Daily revenue
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null) {
            final dayKey = '${createdAt.day}/${createdAt.month}';
            _dailyRevenue[dayKey] = (_dailyRevenue[dayKey] ?? 0) + total;
          }
          
          // Top dishes
          final items = data['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            final dishName = item['dishName'] ?? 'Noma\'lum';
            final qty = ((item['quantity'] ?? 1) as num).round();
            dishCount[dishName] = (dishCount[dishName] ?? 0) + qty;
          }
        }
      }
      
      // Calculate average check
      _averageCheck = _paidOrders > 0 ? _totalRevenue / _paidOrders : 0;
      
      // Sort and get top 5 dishes
      final sortedDishes = dishCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topDishes = Map.fromEntries(sortedDishes.take(5));
      
      // Load reviews
      final reviewsQuery = await firestore
          .collection('reviews')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .get();
      
      _totalReviews = reviewsQuery.docs.length;
      if (_totalReviews > 0) {
        double totalRating = 0;
        for (var doc in reviewsQuery.docs) {
          totalRating += (doc['rating'] ?? 0).toDouble();
        }
        _averageRating = totalRating / _totalReviews;
      }
    } catch (e) {
      debugPrint('Error loading report data: $e');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');
    final currencyFormat = NumberFormat.currency(locale: 'uz', symbol: "sum", decimalDigits: 0);
    
    // Aesthetic dark theme override for this screen
    final isDark = true; 

    return Scaffold(
      backgroundColor: AppColors.darkBgTop, // Force dark background for Ethereal look
      appBar: AppBar(
        title: Text(
          'reports'.tr(),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
            tooltip: 'export_pdf'.tr(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkBackgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.etherealLime))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Selector
                      EtherealCard(
                        onTap: _selectDateRange,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.etherealLime.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calendar_today, color: AppColors.etherealLime),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'report_period'.tr(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: Colors.white54),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Text(
                        'overview'.tr(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Main Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: GradientStatCard(
                              title: 'total_revenue'.tr(),
                              value: currencyFormat.format(_totalRevenue).replaceAll('sum', '').trim(),
                              subtitle: '+15.7% o\'sish',
                              icon: Icons.payments,
                              gradient: AppColors.etherealGreenGradient,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _CompactStatCard(
                                  title: 'bookings'.tr(),
                                  value: _totalBookings.toString(),
                                  icon: Icons.confirmation_number,
                                  color: AppColors.etherealPurple,
                                ),
                                const SizedBox(height: 16),
                                _CompactStatCard(
                                  title: 'rating'.tr(),
                                  value: _averageRating.toStringAsFixed(1),
                                  icon: Icons.star,
                                  color: AppColors.starGold,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // New: Orders & Average Check Row
                      Row(
                        children: [
                          Expanded(
                            child: _CompactStatCard(
                              title: 'O\'rtacha chek',
                              value: currencyFormat.format(_averageCheck).replaceAll('sum', '').trim(),
                              icon: Icons.receipt_long,
                              color: AppColors.etherealLime,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CompactStatCard(
                              title: 'Buyurtmalar',
                              value: '$_paidOrders / $_totalOrders',
                              icon: Icons.shopping_bag,
                              color: AppColors.etherealPurple,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tips & Discount Row
                      Row(
                        children: [
                          Expanded(
                            child: _CompactStatCard(
                              title: 'Choyxona (Tips)',
                              value: currencyFormat.format(_totalTips).replaceAll('sum', '').trim(),
                              icon: Icons.volunteer_activism,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _CompactStatCard(
                              title: 'Chegirmalar',
                              value: currencyFormat.format(_totalDiscount).replaceAll('sum', '').trim(),
                              icon: Icons.discount,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Charts Section
                      EtherealCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'booking_stats'.tr(),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.etherealLime.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.bar_chart, color: AppColors.etherealLime, size: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            EtherealBarChart(
                              values: [
                                _totalBookings.toDouble(),
                                _confirmedBookings.toDouble(),
                                _cancelledBookings.toDouble(),
                                _totalReviews.toDouble(),
                              ],
                              labels: ['Jami', 'Tasdiq', 'Bekor', 'Sharhlar'],
                              primaryColor: AppColors.etherealLime,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Reviews Pie Chart
                      Row(
                        children: [
                          Expanded(
                            child: EtherealCard(
                              child: Column(
                                children: [
                                  Text(
                                    'status_split'.tr(),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  EtherealPieChart(
                                    data: {
                                      'Tasdiq': _confirmedBookings.toDouble(),
                                      'Bekor': _cancelledBookings.toDouble(),
                                    },
                                    colors: [
                                      AppColors.etherealPurple,
                                      AppColors.etherealPink,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: EtherealCard(
                              onTap: _generatePdf,
                              backgroundColor: AppColors.etherealDeepBlue.withOpacity(0.1),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.download, color: AppColors.etherealDeepBlue, size: 28),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'export_report'.tr(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'PDF Format',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Top Dishes Section
                      if (_topDishes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        EtherealCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.restaurant_menu, color: AppColors.etherealLime),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Top Taomlar',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._topDishes.entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.etherealLime.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${entry.value} ta',
                                        style: const TextStyle(
                                          color: AppColors.etherealLime,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                      
                      // Daily Revenue Chart
                      if (_dailyRevenue.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        EtherealCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.show_chart, color: AppColors.etherealLime),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Kunlik Daromad',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: _dailyRevenue.values.isNotEmpty 
                                          ? (_dailyRevenue.values.reduce((a, b) => a > b ? a : b) / 4).clamp(1, double.infinity)
                                          : 1,
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: Colors.white.withOpacity(0.1),
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 && index < _dailyRevenue.keys.length) {
                                              return Text(
                                                _dailyRevenue.keys.elementAt(index),
                                                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _dailyRevenue.entries.toList().asMap().entries.map((e) {
                                          return FlSpot(e.key.toDouble(), e.value.value / 1000);
                                        }).toList(),
                                        isCurved: true,
                                        color: AppColors.etherealLime,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: true),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: AppColors.etherealLime.withOpacity(0.2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '* ming so\'mda',
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.etherealLime,
              onPrimary: Colors.black,
              surface: AppColors.darkCardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadData();
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'uz', symbol: "so'm", decimalDigits: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  widget.choyxonaName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Hisobot davri: ${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.Divider(height: 40),
              
              pw.Text(
                'Buyurtmalar statistikasi',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildPdfRow('Jami bronlar', _totalBookings.toString()),
              _buildPdfRow('Tasdiqlangan bronlar', _confirmedBookings.toString()),
              _buildPdfRow('Bekor qilingan bronlar', _cancelledBookings.toString()),
              _buildPdfRow('Jami buyurtmalar', _totalOrders.toString()),
              _buildPdfRow('To\'langan buyurtmalar', _paidOrders.toString()),
              
              pw.SizedBox(height: 24),
              
              pw.Text(
                'Moliyaviy ko\'rsatkichlar',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildPdfRow('Umumiy daromad', currencyFormat.format(_totalRevenue)),
              _buildPdfRow('O\'rtacha chek', currencyFormat.format(_averageCheck)),
              _buildPdfRow('Tips (Choyxona)', currencyFormat.format(_totalTips)),
              _buildPdfRow('Chegirmalar', currencyFormat.format(_totalDiscount)),
              
              pw.SizedBox(height: 24),
              
              pw.Text(
                'Baholash',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              _buildPdfRow('O\'rtacha reyting', '${_averageRating.toStringAsFixed(1)} / 5.0'),
              _buildPdfRow('Jami sharhlar', _totalReviews.toString()),
              
              if (_topDishes.isNotEmpty) ...[
                pw.SizedBox(height: 24),
                pw.Text(
                  'Top taomlar',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                ..._topDishes.entries.map((e) => _buildPdfRow(e.key, '${e.value} ta')),
              ],
              
              pw.Spacer(),
              
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Generatsiya vaqti: ${dateFormat.format(DateTime.now())} | Choyxona.uz',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${widget.choyxonaName}_report_${dateFormat.format(DateTime.now())}.pdf',
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return EtherealCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

