import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'choyxona_analytics_screen.dart';
import '../reports/cash_register_report_screen.dart';

/// 📊💰 Birlashgan Tahlil va Kassa ekrani
class CombinedAnalyticsScreen extends StatefulWidget {
  final String choyxonaId;
  final String choyxonaName;
  
  const CombinedAnalyticsScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  State<CombinedAnalyticsScreen> createState() => _CombinedAnalyticsScreenState();
}

class _CombinedAnalyticsScreenState extends State<CombinedAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgTop,
      appBar: AppBar(
        title: Text(
          'Tahlil & Kassa',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.etherealLime,
          labelColor: AppColors.etherealLime,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Tahlil',
            ),
            Tab(
              icon: Icon(Icons.point_of_sale),
              text: 'Kassa',
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkBackgroundGradient,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tahlil (Analytics) tab
            _AnalyticsTabContent(
              choyxonaId: widget.choyxonaId,
              choyxonaName: widget.choyxonaName,
            ),
            // Kassa (Cash Register) tab
            _CashRegisterTabContent(
              choyxonaId: widget.choyxonaId,
              choyxonaName: widget.choyxonaName,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tahlil tab - ChoyxonaAnalyticsScreen'dan content
class _AnalyticsTabContent extends StatelessWidget {
  final String choyxonaId;
  final String choyxonaName;

  const _AnalyticsTabContent({
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  Widget build(BuildContext context) {
    return ChoyxonaAnalyticsScreen(
      choyxonaId: choyxonaId,
      choyxonaName: choyxonaName,
      embedded: true, // AppBar ko'rsatmaslik uchun
    );
  }
}

/// Kassa tab - CashRegisterReportScreen'dan content
class _CashRegisterTabContent extends StatelessWidget {
  final String choyxonaId;
  final String choyxonaName;

  const _CashRegisterTabContent({
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  Widget build(BuildContext context) {
    return CashRegisterReportScreen(
      choyxonaId: choyxonaId,
      choyxonaName: choyxonaName,
      embedded: true, // AppBar ko'rsatmaslik uchun
    );
  }
}
