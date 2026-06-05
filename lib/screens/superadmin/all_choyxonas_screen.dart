import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/choyxona_model.dart';
import '../owner/add_choyxona_screen.dart';
import '../owner/edit_choyxona_screen.dart';
import 'assign_admin_screen.dart';

/// Экран управления всеми чайханами (Super Admin)
class AllChoyxonasScreen extends StatefulWidget {
  const AllChoyxonasScreen({super.key});

  @override
  State<AllChoyxonasScreen> createState() => _AllChoyxonasScreenState();
}

class _AllChoyxonasScreenState extends State<AllChoyxonasScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive
  bool _isReorderMode = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Barcha choyxonalar'),
        actions: [
          // Reorder Toggle
          IconButton(
            onPressed: () {
              setState(() {
                _isReorderMode = !_isReorderMode;
                // If exiting reorder mode, reset filters
                if (_isReorderMode) {
                  _searchQuery = '';
                  _filterStatus = 'all';
                }
              });
              if (_isReorderMode) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tartiblash rejimi yoqildi. Suring va joylashtiring! ↕️'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: Icon(
              _isReorderMode ? Icons.check : Icons.sort,
              color: _isReorderMode ? AppColors.success : null,
            ),
            tooltip: _isReorderMode ? 'Tartiblashni tugatish' : 'Tartibni o\'zgartirish',
          ),
          if (!_isReorderMode) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) => setState(() => _filterStatus = value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('Barchasi')),
                const PopupMenuItem(value: 'active', child: Text('Faol')),
                const PopupMenuItem(value: 'inactive', child: Text('Nofaol')),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search (hidden in reorder mode)
          if (!_isReorderMode)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Nom bo\'yicha qidirish...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('choyxonas')
                  // Always get all docs, we sort manually
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                var docs = snapshot.data!.docs;
                var dataList = docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  data['id'] = d.id; // Ensure ID is present
                  // Ensure sortOrder for sorting logic
                  if (data['sortOrder'] == null) {
                    data['sortOrder'] = 9999;
                  }
                  return data;
                }).toList();
                
                // Always sort by sortOrder first for consistent display
                dataList.sort((a, b) {
                  final aOrder = (a['sortOrder'] as int?) ?? 9999;
                  final bOrder = (b['sortOrder'] as int?) ?? 9999;
                  return aOrder.compareTo(bOrder);
                });

                // Apply filters if NOT in reorder mode
                if (!_isReorderMode) {
                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    dataList = dataList.where((data) {
                      final name = data['name']?.toString().toLowerCase() ?? '';
                      return name.contains(_searchQuery);
                    }).toList();
                  }

                  // Status filter
                  if (_filterStatus != 'all') {
                    dataList = dataList.where((data) {
                      final status = data['status'] ?? 'active';
                      return _filterStatus == 'active' ? status == 'active' : status != 'active';
                    }).toList();
                  }
                }

                if (_isReorderMode) {
                  // Reorderable List
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: dataList.length,
                    onReorder: (oldIndex, newIndex) => _onReorder(dataList, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final data = dataList[index];
                      return _buildChoyxonaCard(
                        data['id'], 
                        data, 
                        isDark, 
                        isReorderable: true,
                        key: ValueKey(data['id']),
                        index: index,
                      );
                    },
                  );
                } else {
                  // Normal List
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: dataList.length,
                    itemBuilder: (context, index) {
                      final data = dataList[index];
                      return _buildChoyxonaCard(data['id'], data, isDark);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !_isReorderMode 
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddChoyxonaScreen()),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Qo\'shish', style: TextStyle(color: Colors.white)),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }

  Future<void> _onReorder(List<Map<String, dynamic>> items, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    
    // UI update is handled by stream, but we need to update DB immediately
    // Create a local modifyable copy to calculate new indices (logic only)
    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    // Show feedback
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saqlanmoqda... ⏳'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.info,
      ),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (int i = 0; i < items.length; i++) {
        final docRef = FirebaseFirestore.instance
            .collection('choyxonas')
            .doc(items[i]['id']);
        batch.update(docRef, {'sortOrder': i});
      }
      
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tartib saqlandi! ✅'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildChoyxonaCard(String id, Map<String, dynamic> data, bool isDark, {bool isReorderable = false, Key? key, int? index}) {
    final name = data['name'] ?? '';
    final addressData = data['address'];
    final addressStr = addressData is Map ? '${addressData['city'] ?? ''}, ${addressData['street'] ?? ''}' : '';
    final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final status = data['status'] ?? 'active';
    final isActive = status == 'active';
    final images = List<String>.from(data['images'] ?? []);
    final bookingCount = data['bookingCount'] ?? 0;
    final isFeatured = data['isFeatured'] ?? false;

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      color: isReorderable && isFeatured 
          ? AppColors.warning.withOpacity(0.1) 
          : (isDark ? AppColors.darkSurface : AppColors.surface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: isReorderable ? null : () => _showChoyxonaActions(id, data),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (isReorderable && index != null) ...[
                // Order Number
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: images.isNotEmpty
                    ? Image.network(
                        images.first,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isFeatured)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.star, color: AppColors.warning, size: 16),
                          ),
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isReorderable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.success : AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'Faol' : 'Nofaol',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      addressStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (!isReorderable)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.starGold),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.book_online, size: 14, 
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '$bookingCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (isReorderable)
                 const Icon(Icons.drag_handle, color: Colors.grey)
              else
                 const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.restaurant, color: AppColors.textLight),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(
            'Choyxonalar topilmadi',
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showChoyxonaActions(String id, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = data['status'] ?? 'active';
    final isActive = status == 'active';
    final name = data['name'] ?? '';
    final addressData = data['address'];
    final addressStr = addressData is Map 
        ? '${addressData['city'] ?? ''}, ${addressData['street'] ?? ''}' 
        : '';
    final isFeatured = data['isFeatured'] ?? false;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Tahrirlash'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditChoyxonaScreen(
                      choyxonaId: id,
                      choyxonaData: data,
                    ),
                  ),
                );
              },
            ),
             ListTile(
              leading: Icon(
                isFeatured ? Icons.star : Icons.star_border,
                color: isFeatured ? AppColors.warning : null,
              ),
              title: Text(isFeatured ? 'Tanlanganlardan olish' : 'Tanlangan qilish'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('choyxonas')
                    .doc(id)
                    .update({'isFeatured': !isFeatured});
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Admin tayinlash'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AssignAdminScreen(
                      choyxonaId: id,
                      choyxonaName: name,
                      choyxonaAddress: addressStr,
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: Icon(
                isActive ? Icons.visibility_off : Icons.visibility,
              ),
              title: Text(isActive ? 'Nofaol qilish' : 'Faollashtirish'),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('choyxonas')
                    .doc(id)
                    .update({'status': isActive ? 'inactive' : 'active'});
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('O\'chirish', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                _deleteChoyxona(id, name);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteChoyxona(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choyxonani o\'chirish?'),
        content: Text('Siz rostdan ham "$name"ni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('choyxonas')
          .doc(id)
          .delete();
    }
  }
}
