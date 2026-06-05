import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';


/// Экран расширенного поиска
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedPriceRange = 'all';
  double _maxDistance = 10.0;
  bool _onlyOpen = false;
  bool _hasParking = false;
  bool _hasWifi = false;
  
  // Yangi filtrlar
  double _minRating = 0.0; // 0 = barcha, 3, 3.5, 4, 4.5
  List<String> _selectedCuisineTypes = [];

  // Oshxona turlari ro'yxati
  final List<Map<String, String>> _cuisineTypes = [
    {'value': 'national', 'label': 'cuisine_national', 'desc': 'cuisine_national_desc'},
    {'value': 'oriental', 'label': 'cuisine_oriental', 'desc': 'cuisine_oriental_desc'},
    {'value': 'european', 'label': 'cuisine_european', 'desc': ''},
    {'value': 'mixed', 'label': 'cuisine_mixed', 'desc': ''},
    // Mavjud qiymatlar bilan moslashtirish
    {'value': 'uzbek', 'label': 'cuisine_uzbek', 'desc': 'cuisine_national_desc'},
    {'value': 'asian', 'label': 'cuisine_asian', 'desc': ''},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('search'.tr()),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Поисковая строка
            _buildSearchBar(context),

            const SizedBox(height: 24),

            // Фильтры
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'filters'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 16),

                  // Reyting filtri
                  _buildRatingFilter(context),
                  
                  const SizedBox(height: 24),

                  // Oshxona turi filtri
                  _buildCuisineTypeFilter(context),
                  
                  const SizedBox(height: 24),

                  // Ценовой диапазон
                  _buildPriceRangeFilter(context),

                  const SizedBox(height: 24),

                  // Расстояние
                  _buildDistanceFilter(context),

                  const SizedBox(height: 24),

                  // Дополнительные опции
                  _buildAdditionalOptions(context),

                  const SizedBox(height: 24),

                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFilters,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(color: Theme.of(context).primaryColor),
                          ),
                          child: Text('reset'.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('apply'.tr()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: TextField(
        controller: _searchController,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'search_by_name_or_address'.tr(),
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextLight : AppColors.textLight,
          ),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchController.clear();
              });
            },
          )
              : null,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Reyting filtri
  Widget _buildRatingFilter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    final ratingOptions = [
      {'value': 0.0, 'label': 'rating_all'},
      {'value': 3.0, 'label': '3+'},
      {'value': 3.5, 'label': '3.5+'},
      {'value': 4.0, 'label': '4+'},
      {'value': 4.5, 'label': '4.5+'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'rating_filter'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ratingOptions.map((option) {
              final isSelected = _minRating == option['value'];
              final label = option['value'] == 0.0 
                  ? 'rating_all'.tr() 
                  : option['label'] as String;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _minRating = option['value'] as double;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryColor : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (option['value'] != 0.0) ...[
                          Icon(
                            Icons.star,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.amber,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          label,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _minRating > 0 
              ? '${_minRating.toString()} ${'stars_and_above'.tr()}'
              : '',
          style: AppTextStyles.labelSmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Oshxona turi filtri
  Widget _buildCuisineTypeFilter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'cuisine_filter'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cuisineTypes.map((cuisine) {
            final isSelected = _selectedCuisineTypes.contains(cuisine['value']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCuisineTypes.remove(cuisine['value']);
                  } else {
                    _selectedCuisineTypes.add(cuisine['value']!);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? primaryColor.withOpacity(0.15) 
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primaryColor : Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: primaryColor,
                      ),
                    if (isSelected) const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cuisine['label']!.tr(),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected ? primaryColor : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (cuisine['desc']!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            cuisine['desc']!.tr(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'price_range'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPriceChip(context, '\$', 'price_cheap'.tr(), '\$'),
            const SizedBox(width: 8),
            _buildPriceChip(context, '\$\$', 'price_medium'.tr(), '\$\$'),
            const SizedBox(width: 8),
            _buildPriceChip(context, '\$\$\$', 'price_expensive'.tr(), '\$\$\$'),
            const SizedBox(width: 8),
            _buildPriceChip(context, 'all'.tr(), 'all'.tr(), 'all'),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceChip(BuildContext context, String label, String hint, String value) {
    final isSelected = _selectedPriceRange == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPriceRange = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected ? Colors.white : primaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.8) 
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'max_distance'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${_maxDistance.toStringAsFixed(0)} ${'km'.tr()}',
              style: AppTextStyles.labelLarge.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        Slider(
          value: _maxDistance,
          min: 1,
          max: 30,
          divisions: 29,
          activeColor: Theme.of(context).primaryColor,
          onChanged: (value) {
            setState(() {
              _maxDistance = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'additional'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildCheckboxOption(
          context,
          'only_open_now'.tr(),
          _onlyOpen,
              (value) => setState(() => _onlyOpen = value!),
        ),
        _buildCheckboxOption(
          context,
          'with_parking'.tr(),
          _hasParking,
              (value) => setState(() => _hasParking = value!),
        ),
        _buildCheckboxOption(
          context,
          'with_wifi'.tr(),
          _hasWifi,
              (value) => setState(() => _hasWifi = value!),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption(BuildContext context, String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedPriceRange = 'all';
      _maxDistance = 10.0;
      _onlyOpen = false;
      _hasParking = false;
      _hasWifi = false;
      _minRating = 0.0;
      _selectedCuisineTypes = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('filters_reset'.tr()),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _applyFilters() {
    // Filtrlarni qaytarish
    final filters = {
      'searchQuery': _searchController.text,
      'priceRange': _selectedPriceRange,
      'maxDistance': _maxDistance,
      'onlyOpen': _onlyOpen,
      'hasParking': _hasParking,
      'hasWifi': _hasWifi,
      'minRating': _minRating,
      'cuisineTypes': _selectedCuisineTypes,
    };
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('filters_applied'.tr()),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
    
    // Filtrlar bilan orqaga qaytish
    Navigator.pop(context, filters);
  }
}
