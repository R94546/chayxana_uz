import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/design/choy_tokens.dart';
import '../../core/design/choy_components.dart';
import '../../core/utils/responsive_layout.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../models/choyxona_model.dart';
import 'widgets/choyxona_card.dart';
import 'widgets/active_booking_banner.dart';
import '../choyxona_details/choyxona_details_screen.dart';
import '../notifications/notifications_list_screen.dart';
import '../search/search_screen.dart';

/// 🍵 User bosh ekrani — premium choyxona redizayn (Faza 4).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchQuery = '';
  Map<String, int> _categoryCounts = {};

  // Filtr o'zgaruvchilari (Qidiruv ekranidan qaytadi)
  double _minRating = 0.0;
  List<String> _selectedCuisineTypes = [];
  String _selectedPriceRange = 'all';
  bool _onlyOpen = false;
  bool _hasParking = false;
  bool _hasWifi = false;
  bool _filtersApplied = false;

  static const _categories = ['all', 'traditional', 'modern', 'premium'];

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    await LocationService.instance.initialize();
    if (mounted) setState(() {});
  }

  void _loadCounts() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('choyxonas').get();
      if (!mounted) return;
      int traditional = 0, modern = 0, premium = 0, total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if ((data['status'] as String? ?? 'active') != 'active') continue;
        total++;
        final category = data['category'] as String? ?? 'traditional';
        if (category == 'traditional') {
          traditional++;
        } else if (category == 'modern' || category == 'fast_casual') {
          modern++;
        } else if (category == 'premium' || category == 'fine_dining') {
          premium++;
        }
      }
      setState(() {
        _categoryCounts = {
          'all': total,
          'traditional': traditional,
          'modern': modern,
          'premium': premium,
        };
      });
    } catch (_) {}
  }

  void _openSearchScreen() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _searchQuery = result['searchQuery'] as String? ?? '';
        _searchController.text = _searchQuery;
        _selectedPriceRange = result['priceRange'] as String? ?? 'all';
        _minRating = result['minRating'] as double? ?? 0.0;
        _selectedCuisineTypes =
            List<String>.from(result['cuisineTypes'] ?? []);
        _onlyOpen = result['onlyOpen'] as bool? ?? false;
        _hasParking = result['hasParking'] as bool? ?? false;
        _hasWifi = result['hasWifi'] as bool? ?? false;
        _filtersApplied = _minRating > 0 ||
            _selectedCuisineTypes.isNotEmpty ||
            _selectedPriceRange != 'all' ||
            _onlyOpen ||
            _hasParking ||
            _hasWifi;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _minRating = 0.0;
      _selectedCuisineTypes = [];
      _selectedPriceRange = 'all';
      _onlyOpen = false;
      _hasParking = false;
      _hasWifi = false;
      _filtersApplied = false;
    });
  }

  String get _greetingKey {
    final h = DateTime.now().hour;
    if (h < 12) return 'greeting_morning';
    if (h < 18) return 'greeting_afternoon';
    return 'greeting_evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    SystemChrome.setSystemUIOverlayStyle(
      c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(c)),
            const SliverToBoxAdapter(child: ActiveBookingBanner()),
            SliverToBoxAdapter(child: _buildSearchBar(c)),
            if (_filtersApplied)
              SliverToBoxAdapter(child: _buildFilterIndicator(c)),
            SliverToBoxAdapter(child: _buildCategories(c)),
            _buildChoyxonaList(c),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ChoyColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          ChoySpace.xl, ChoySpace.lg, ChoySpace.xl, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingKey.tr(),
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'find_perfect_place'.tr(),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ChoySpace.md),
          _buildNotificationBell(c),
        ],
      ),
    );
  }

  Widget _buildNotificationBell(ChoyColors c) {
    Widget bellButton(int unread) => Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                shape: BoxShape.circle,
                border: Border.all(color: c.border),
              ),
              child: IconButton(
                icon: Icon(Icons.notifications_none_rounded,
                    color: c.textPrimary),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsListScreen()),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: ChoyPalette.danger, shape: BoxShape.circle),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );

    return FutureBuilder<String?>(
      future: AuthService().getCurrentUserData().then((u) => u?.userId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return bellButton(0);
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: userSnapshot.data)
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) =>
              bellButton(snapshot.data?.docs.length ?? 0),
        );
      },
    );
  }

  Widget _buildSearchBar(ChoyColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          ChoySpace.xl, ChoySpace.xl, ChoySpace.xl, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openSearchScreen,
          borderRadius: ChoyRadius.all(ChoyRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: ChoySpace.lg, vertical: ChoySpace.lg),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: ChoyRadius.all(ChoyRadius.lg),
              border: Border.all(color: c.border),
              boxShadow: ChoyShadow.card(c.isDark),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: c.textMuted),
                const SizedBox(width: ChoySpace.md),
                Expanded(
                  child: Text(
                    'search_choyxona'.tr(),
                    style: TextStyle(color: c.textMuted, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: ChoyRadius.all(ChoyRadius.md),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterIndicator(ChoyColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ChoySpace.xl, ChoySpace.md, 0, 0),
      child: Row(
        children: [
          ChoyStatusBadge(
            label: 'filters_applied'.tr(),
            tone: ChoyStatusTone.info,
            icon: Icons.filter_list_rounded,
          ),
          const SizedBox(width: ChoySpace.sm),
          GestureDetector(
            onTap: _clearFilters,
            child: ChoyStatusBadge(
              label: 'reset'.tr(),
              tone: ChoyStatusTone.danger,
              icon: Icons.clear_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(ChoyColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: ChoySpace.xl),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ChoySpace.xl),
        child: Row(
          children: [
            for (final cat in _categories) ...[
              ChoyChip(
                label: 'category_$cat'.tr() +
                    (_categoryCounts[cat] != null
                        ? '  ${_categoryCounts[cat]}'
                        : ''),
                selected: _selectedCategory == cat,
                onTap: () => setState(() => _selectedCategory = cat),
              ),
              const SizedBox(width: ChoySpace.sm),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChoyxonaList(ChoyColors c) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('choyxonas').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: c.primary),
            ),
          );
        }

        final choyxonas = snapshot.data!.docs
            .map((d) => Choyxona.fromFirestore(d))
            .toList()
          ..sort((a, b) =>
              (a.sortOrder ?? 9999).compareTo(b.sortOrder ?? 9999));

        final filtered = choyxonas.where(_matchesFilters).toList();

        if (filtered.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: ChoyEmptyState(
              icon: Icons.search_off_rounded,
              title: 'no_choyxonas_found'.tr(),
              action: _filtersApplied
                  ? ChoyButton(
                      label: 'reset'.tr(),
                      icon: Icons.clear_rounded,
                      variant: ChoyButtonVariant.secondary,
                      expanded: false,
                      onPressed: _clearFilters,
                    )
                  : null,
            ),
          );
        }

        final isDesktop = ResponsiveLayout.isDesktop(context);
        final isTablet = ResponsiveLayout.isTablet(context);
        final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);
        final hPad = ResponsiveLayout.getHorizontalPadding(context);

        void openDetails(Choyxona ch) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChoyxonaDetailsScreen(choyxona: ch),
              ),
            );

        if (crossAxisCount > 1) {
          return SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, ChoySpace.xxl, hPad, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: ChoySpace.lg,
                crossAxisSpacing: ChoySpace.lg,
                childAspectRatio: 1.6,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ChoyxonaCard(
                  choyxona: filtered[index],
                  onTap: () => openDetails(filtered[index]),
                ),
                childCount: filtered.length,
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad, ChoySpace.xxl, hPad, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ChoyxonaCard(
                choyxona: filtered[index],
                onTap: () => openDetails(filtered[index]),
              ),
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }

  bool _matchesFilters(Choyxona c) {
    if (c.status != 'active') return false;
    if (_searchQuery.isNotEmpty &&
        !c.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
      return false;
    }
    if (_selectedCategory != 'all') {
      final matches = _selectedCategory == 'modern'
          ? (c.category == 'modern' || c.category == 'fast_casual')
          : _selectedCategory == 'premium'
              ? (c.category == 'premium' || c.category == 'fine_dining')
              : c.category == _selectedCategory;
      if (!matches) return false;
    }
    if (_minRating > 0 && c.reviewCount >= 3 && c.rating < _minRating) {
      return false;
    }
    if (_selectedCuisineTypes.isNotEmpty) {
      final hasCuisine = c.cuisine.any((cuisine) =>
          _selectedCuisineTypes.contains(cuisine) ||
          (_selectedCuisineTypes.contains('national') &&
              cuisine == 'uzbek') ||
          (_selectedCuisineTypes.contains('uzbek') &&
              cuisine == 'national') ||
          (_selectedCuisineTypes.contains('oriental') &&
              cuisine == 'asian') ||
          (_selectedCuisineTypes.contains('asian') &&
              cuisine == 'oriental'));
      if (!hasCuisine) return false;
    }
    if (_selectedPriceRange != 'all' && c.priceRange != _selectedPriceRange) {
      return false;
    }
    if (_onlyOpen && !c.isOpenNow()) return false;
    if (_hasParking && !c.features.contains('parking')) return false;
    if (_hasWifi && !c.features.contains('wifi')) return false;
    return true;
  }
}
