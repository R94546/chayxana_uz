import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../models/menu_item_model.dart';
import '../../models/dish_model.dart';
import '../../services/menu_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 🍽️ Экран просмотра меню (для клиентов, включая из QR)
class MenuViewScreen extends StatefulWidget {
  final String choyxonaId;
  final String choyxonaName;
  
  const MenuViewScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  State<MenuViewScreen> createState() => _MenuViewScreenState();
}

class _MenuViewScreenState extends State<MenuViewScreen> {
  final MenuService _menuService = MenuService();
  String? _selectedCategory;
  
  final List<String> _categories = [
    'main',
    'soup',
    'salad',
    'appetizer',
    'beverage',
    'dessert',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.locale.languageCode;
    final priceFormat = NumberFormat.currency(locale: 'uz', symbol: "so'm", decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.choyxonaName),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBackgroundGradient(isDark),
        ),
        child: Column(
          children: [
            // Категории
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryChip(
                      label: 'all'.tr(),
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                      isDark: isDark,
                    );
                  }
                  final category = _categories[index - 1];
                  return _CategoryChip(
                    label: MenuItem.getCategoryName(category, locale),
                    isSelected: _selectedCategory == category,
                    onTap: () => setState(() => _selectedCategory = category),
                    isDark: isDark,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Меню
            Expanded(
              child: StreamBuilder<List<DishModel>>(
                stream: _menuService.streamDishes(widget.choyxonaId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('error_loading'.tr()));
                  }
                  
                  var items = snapshot.data ?? [];
                  
                  // Фильтруем по категории и доступности
                  items = items.where((item) => item.isAvailable).toList();
                  if (_selectedCategory != null) {
                    items = items.where((item) => item.category == _selectedCategory).toList();
                  }
                  
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'no_menu_items'.tr(),
                            style: TextStyle(
                              color: AppColors.getTextSecondary(isDark),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _MenuItemCard(
                        item: item,
                        locale: locale,
                        priceFormat: priceFormat,
                        isDark: isDark,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: isDark ? AppColors.darkCardBg : Colors.white,
        selectedColor: AppColors.getPrimary(isDark).withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected 
              ? AppColors.getPrimary(isDark)
              : AppColors.getTextPrimary(isDark),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected 
              ? AppColors.getPrimary(isDark) 
              : Colors.transparent,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final DishModel item;
  final String locale;
  final NumberFormat priceFormat;
  final bool isDark;
  
  const _MenuItemCard({
    required this.item,
    required this.locale,
    required this.priceFormat,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.getCardBg(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Изображение
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBgMiddle : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
            ),
            
            const SizedBox(width: 12),
            
            // Информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название и популярность
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.getTextPrimary(isDark),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: AppColors.warning),
                              const SizedBox(width: 2),
                              Text(
                                'hit'.tr(),
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Описание
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: TextStyle(
                        color: AppColors.getTextSecondary(isDark),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Цена и время
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceFormat.format(item.price),
                        style: TextStyle(
                          color: AppColors.getPrimary(isDark),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (item.preparationTime > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: AppColors.getTextSecondary(isDark),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.preparationTime} ${'min'.tr()}',
                              style: TextStyle(
                                color: AppColors.getTextSecondary(isDark),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
