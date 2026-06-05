import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/menu_item_model.dart';

/// Экран управления меню чайханы
class MenuManagementScreen extends StatefulWidget {
  final String choyxonaId;
  final String choyxonaName;

  const MenuManagementScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'Все'},
    {'value': 'main', 'label': 'Основные блюда'},
    {'value': 'soup', 'label': 'Супы'},
    {'value': 'salad', 'label': 'Салаты'},
    {'value': 'appetizer', 'label': 'Закуски'},
    {'value': 'dessert', 'label': 'Десерты'},
    {'value': 'beverage', 'label': 'Напитки'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('menu_management'.tr()),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Категории
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat['label']!),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat['value']!),
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Список блюд
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMenuStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                final items = snapshot.data!.docs
                    .map((doc) => MenuItem.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildMenuItem(items[index], isDark),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('add_dish'.tr(), style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Stream<QuerySnapshot> _getMenuStream() {
    var query = FirebaseFirestore.instance
        .collection('menu_items')
        .where('choyxonaId', isEqualTo: widget.choyxonaId);

    if (_selectedCategory != 'all') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots();
  }

  Widget _buildMenuItem(MenuItem item, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: item.imageUrl.isNotEmpty
              ? Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover)
              : Container(
                  width: 60,
                  height: 60,
                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                  child: const Icon(Icons.restaurant_menu),
                ),
        ),
        title: Text(
          item.name,
          style: AppTextStyles.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MenuItem.getCategoryName(item.category, 'ru'),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${item.price.toStringAsFixed(0)} сум',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isAvailable ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.isAvailable ? 'В наличии' : 'Нет в наличии',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(item);
            } else if (value == 'toggle') {
              _toggleAvailability(item);
            } else if (value == 'delete') {
              _deleteItem(item);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(item.isAvailable ? 'Отметить недоступным' : 'Отметить доступным'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Удалить', style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: isDark ? AppColors.darkTextLight : AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Меню пусто',
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте первое блюдо',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditDialog(MenuItem? item) async {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toStringAsFixed(0) ?? '');
    String category = item?.category ?? 'main';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Редактировать блюдо' : 'Добавить блюдо'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название блюда',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Цена',
                    suffixText: 'сум',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Категория',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.skip(1).map((cat) => DropdownMenuItem(
                    value: cat['value'],
                    child: Text(cat['label']!),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => category = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final data = {
        'choyxonaId': widget.choyxonaId,
        'name': nameController.text,
        'nameRu': nameController.text,
        'nameUz': nameController.text,
        'nameEn': nameController.text,
        'description': descController.text,
        'category': category,
        'price': double.tryParse(priceController.text) ?? 0,
        'imageUrl': item?.imageUrl ?? '',
        'isAvailable': item?.isAvailable ?? true,
        'isPopular': item?.isPopular ?? false,
        'preparationTime': 15,
        'ingredients': <String>[],
        'createdAt': item?.createdAt != null 
            ? Timestamp.fromDate(item!.createdAt) 
            : FieldValue.serverTimestamp(),
      };

      try {
        if (isEdit) {
          await FirebaseFirestore.instance
              .collection('menu_items')
              .doc(item!.id)
              .update(data);
        } else {
          await FirebaseFirestore.instance
              .collection('menu_items')
              .add(data);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Блюдо обновлено' : 'Блюдо добавлено'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    try {
      await FirebaseFirestore.instance
          .collection('menu_items')
          .doc(item.id)
          .update({'isAvailable': !item.isAvailable});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить блюдо?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('menu_items')
            .doc(item.id)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Блюдо удалено'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}
