import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../models/choyxona_model.dart';
import 'widgets/glassmorphic_search_bar.dart';
import 'widgets/category_cards.dart';
import 'widgets/choyxona_card.dart';
import '../choyxona_details/choyxona_details_screen.dart';
import '../notifications/notifications_list_screen.dart';
import '../search/search_screen.dart';

/// 📱 PIXEL-PERFECT Home Screen
/// Matches reference images exactly
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
  
  // Yangi filtr o'zgaruvchilari
  double _minRating = 0.0;
  List<String> _selectedCuisineTypes = [];
  String _selectedPriceRange = 'all';
  bool _onlyOpen = false;
  bool _hasParking = false;
  bool _hasWifi = false;
  bool _filtersApplied = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _initLocation();
  }

  Future<void> _initLocation() async {
    await LocationService.instance.initialize();
    if (mounted) setState(() {}); // Обновить UI после получения геолокации
  }

  void _loadCounts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('choyxonas').get();
      if (mounted) {
        int traditional = 0;
        int modern = 0;
        int premium = 0;
        int total = 0;
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          // Faqat faol choyxonalarni hisoblash
          final status = data['status'] as String? ?? 'active';
          if (status != 'active') continue;
          
          total++;
          final category = data['category'] as String? ?? 'traditional';
          // Учитываем все возможные значения категорий
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
      }
    } catch (_) {}
  }

  /// Qidiruv ekraniga o'tish va filtrlarni qabul qilish
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
        _selectedCuisineTypes = List<String>.from(result['cuisineTypes'] ?? []);
        _onlyOpen = result['onlyOpen'] as bool? ?? false;
        _hasParking = result['hasParking'] as bool? ?? false;
        _hasWifi = result['hasWifi'] as bool? ?? false;
        
        // Filtrlar qo'llanganmi tekshirish
        _filtersApplied = _minRating > 0 || 
            _selectedCuisineTypes.isNotEmpty || 
            _selectedPriceRange != 'all' ||
            _onlyOpen ||
            _hasParking ||
            _hasWifi;
      });
    }
  }
  
  /// Filtrlarni tozalash
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Status bar style
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      body: Container(
        // 🎨 Background gradient based on theme
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkBackgroundGradient
              : AppColors.lightBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // 1. Header
              SliverToBoxAdapter(child: _buildHeader(isDark)),

              // 2. Title
              SliverToBoxAdapter(child: _buildTitle(isDark)),

              // 3. Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: GestureDetector(
                    onTap: _openSearchScreen,
                    child: AbsorbPointer(
                      child: GlassmorphicSearchBar(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ),
                  ),
                ),
              ),
              
              // 3.5. Filter indicator
              if (_filtersApplied)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'filters_applied'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _clearFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'reset'.tr(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. Categories
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: CategoryCards(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (cat) =>
                        setState(() => _selectedCategory = cat),
                    categoryCounts: _categoryCounts,
                  ),
                ),
              ),

              // 5. Choyxona List
              _buildChoyxonaList(isDark),

              // Bottom spacing
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo - CHOYXONA.UZ Brand
          Text(
            'CHOYXONA.UZ',
            style: GoogleFonts.inter(
              color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),

          // Right: Notifications
          FutureBuilder<String?>(
            future: AuthService().getCurrentUserData().then((u) => u?.userId),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.white : AppColors.lightHeaderIcon,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
                  ),
                );
              }
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: userSnapshot.data)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data?.docs.length ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: isDark ? Colors.white : AppColors.lightHeaderIcon,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Text(
        'find_perfect_place'.tr(),
        style: GoogleFonts.inter(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightHeadingText,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildChoyxonaList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      // Query all choyxonas
      stream: FirebaseFirestore.instance
          .collection('choyxonas')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.getPrimary(isDark),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final choyxonas = docs.map((d) => Choyxona.fromFirestore(d)).toList();
        
        // Sort by sortOrder (documents without sortOrder go to end)
        choyxonas.sort((a, b) {
          final aOrder = a.sortOrder ?? 9999;
          final bOrder = b.sortOrder ?? 9999;
          return aOrder.compareTo(bOrder);
        });

        // Filter
        final filtered = choyxonas.where((c) {
          // Nofaol choyxonalarni yashirish
          if (c.status != 'active') return false;
          
          // Qidiruv so'rovi bo'yicha filtrlash
          if (_searchQuery.isNotEmpty) {
            if (!c.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
              return false;
            }
          }
          
          // Kategoriya bo'yicha filtrlash
          if (_selectedCategory != 'all') {
            // Маппинг категорий для корректной фильтрации
            final categoryMatches = _selectedCategory == 'modern' 
                ? (c.category == 'modern' || c.category == 'fast_casual')
                : _selectedCategory == 'premium'
                    ? (c.category == 'premium' || c.category == 'fine_dining')
                    : c.category == _selectedCategory;
            if (!categoryMatches) return false;
          }
          
          // Reyting bo'yicha filtrlash
          if (_minRating > 0) {
            // Yangi choyxonalar (kam sharhli) - ko'rsatamiz
            if (c.reviewCount >= 3 && c.rating < _minRating) {
              return false;
            }
          }
          
          // Oshxona turi bo'yicha filtrlash
          if (_selectedCuisineTypes.isNotEmpty) {
            // Choyxonaning oshxona turlari bilan filtr turlari kesishishi kerak
            final hasCuisine = c.cuisine.any((cuisine) => 
              _selectedCuisineTypes.contains(cuisine) ||
              // Mapping: national = uzbek, oriental = asian
              (_selectedCuisineTypes.contains('national') && cuisine == 'uzbek') ||
              (_selectedCuisineTypes.contains('uzbek') && cuisine == 'national') ||
              (_selectedCuisineTypes.contains('oriental') && cuisine == 'asian') ||
              (_selectedCuisineTypes.contains('asian') && cuisine == 'oriental')
            );
            if (!hasCuisine) return false;
          }
          
          // Narx diapazoni bo'yicha filtrlash
          if (_selectedPriceRange != 'all') {
            if (c.priceRange != _selectedPriceRange) return false;
          }
          
          // Faqat ochiq choyxonalar
          if (_onlyOpen && !c.isOpenNow()) return false;
          
          // Parking bor
          if (_hasParking && !c.features.contains('parking')) return false;
          
          // WiFi bor
          if (_hasWifi && !c.features.contains('wifi')) return false;
          
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightSecondaryText,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_choyxonas_found'.tr(),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightSecondaryText,
                      fontSize: 16,
                    ),
                  ),
                  if (_filtersApplied) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear),
                      label: Text('reset'.tr()),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // Responsive: Grid on desktop, List on mobile
        final isDesktop = ResponsiveLayout.isDesktop(context);
        final isTablet = ResponsiveLayout.isTablet(context);
        final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);
        final horizontalPadding = ResponsiveLayout.getHorizontalPadding(context);

        if (crossAxisCount > 1) {
          // Grid layout for tablet/desktop
          return SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return ChoyxonaCard(
                    choyxona: filtered[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChoyxonaDetailsScreen(
                          choyxona: filtered[index],
                        ),
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          );
        }

        // List layout for mobile
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ChoyxonaCard(
                  choyxona: filtered[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChoyxonaDetailsScreen(
                        choyxona: filtered[index],
                      ),
                    ),
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }
}
