import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/design/choy_components.dart';
import '../../core/design/choy_tokens.dart';
import '../../models/menu_item_model.dart';

/// 🍽️ Menyu boshqaruvi — premium redizayn + lokalizatsiya (Faza 4/5).
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

  // value -> lokalizatsiya kaliti
  static const List<Map<String, String>> _categories = [
    {'value': 'all', 'key': 'category_all'},
    {'value': 'main', 'key': 'menu_cat_main'},
    {'value': 'soup', 'key': 'menu_cat_soup'},
    {'value': 'salad', 'key': 'menu_cat_salad'},
    {'value': 'appetizer', 'key': 'menu_cat_appetizer'},
    {'value': 'dessert', 'key': 'menu_cat_dessert'},
    {'value': 'beverage', 'key': 'menu_cat_beverage'},
  ];

  String _catLabel(String value) {
    final cat = _categories.firstWhere((c) => c['value'] == value,
        orElse: () => {'key': value});
    return cat['key']!.tr();
  }

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text('menu_management'.tr())),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: ChoySpace.lg, vertical: ChoySpace.sm),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: ChoySpace.sm),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return ChoyChip(
                  label: cat['key']!.tr(),
                  selected: _selectedCategory == cat['value'],
                  onTap: () =>
                      setState(() => _selectedCategory = cat['value']!),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMenuStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: c.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return ChoyEmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'menu_empty'.tr(),
                    message: 'add_first_dish'.tr(),
                  );
                }
                final items = snapshot.data!.docs
                    .map((doc) => MenuItem.fromFirestore(doc))
                    .toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(ChoySpace.lg),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildMenuItem(items[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(null),
        icon: const Icon(Icons.add_rounded),
        label: Text('add_dish'.tr()),
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

  Widget _buildMenuItem(MenuItem item) {
    final c = ChoyColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: ChoySpace.md),
      child: ChoyCard(
        padding: const EdgeInsets.all(ChoySpace.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: ChoyRadius.all(ChoyRadius.md),
              child: SizedBox(
                width: 60,
                height: 60,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(item.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: c.surfaceVariant,
                            child: Icon(Icons.restaurant_menu_rounded,
                                color: c.textMuted)))
                    : Container(
                        color: c.surfaceVariant,
                        child: Icon(Icons.restaurant_menu_rounded,
                            color: c.textMuted)),
              ),
            ),
            const SizedBox(width: ChoySpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(_catLabel(item.category),
                      style: TextStyle(fontSize: 12, color: c.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${item.price.toStringAsFixed(0)} ${'currency_sum'.tr()}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, color: c.primary)),
                      const Spacer(),
                      ChoyStatusBadge(
                        label: item.isAvailable
                            ? 'in_stock'.tr()
                            : 'out_of_stock'.tr(),
                        tone: item.isAvailable
                            ? ChoyStatusTone.success
                            : ChoyStatusTone.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: c.textMuted),
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
                PopupMenuItem(value: 'edit', child: Text('edit'.tr())),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(item.isAvailable
                      ? 'mark_unavailable'.tr()
                      : 'mark_available'.tr()),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('delete'.tr(),
                      style: const TextStyle(color: ChoyPalette.danger)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(MenuItem? item) async {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final descController = TextEditingController(text: item?.description ?? '');
    final priceController =
        TextEditingController(text: item?.price.toStringAsFixed(0) ?? '');
    String category = item?.category ?? 'main';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'edit_dish'.tr() : 'add_dish'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'dish_name'.tr()),
                ),
                const SizedBox(height: ChoySpace.md),
                TextField(
                  controller: descController,
                  decoration:
                      InputDecoration(labelText: 'dish_description'.tr()),
                  maxLines: 2,
                ),
                const SizedBox(height: ChoySpace.md),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'dish_price'.tr(),
                    suffixText: 'currency_sum'.tr(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: ChoySpace.md),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration:
                      InputDecoration(labelText: 'dish_category'.tr()),
                  items: _categories
                      .skip(1)
                      .map((cat) => DropdownMenuItem(
                            value: cat['value'],
                            child: Text(cat['key']!.tr()),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => category = value!),
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
              .doc(item.id)
              .update(data);
        } else {
          await FirebaseFirestore.instance.collection('menu_items').add(data);
        }
        if (mounted) _snack('dish_saved'.tr());
      } catch (e) {
        if (mounted) _snack('${'error'.tr()}: $e', error: true);
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
      if (mounted) _snack('${'error'.tr()}: $e', error: true);
    }
  }

  Future<void> _deleteItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_dish_title'.tr()),
        content: Text('delete_dish_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr(),
                style: const TextStyle(color: ChoyPalette.danger)),
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
        if (mounted) _snack('dish_saved'.tr());
      } catch (e) {
        if (mounted) _snack('${'error'.tr()}: $e', error: true);
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? ChoyPalette.danger : ChoyPalette.success,
      ),
    );
  }
}
