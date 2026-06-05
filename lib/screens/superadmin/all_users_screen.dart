import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_model.dart';

/// Экран управления всеми пользователями (Super Admin)
class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  String _searchQuery = '';
  String _filterRole = 'all';
  
  // Choyxona nomlari cache
  final Map<String, String> _choyxonaNames = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Все пользователи'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterRole = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Все')),
              const PopupMenuItem(value: 'client', child: Text('Клиенты')),
              const PopupMenuItem(value: 'choyxona_admin', child: Text('Админы чайхан')),
              const PopupMenuItem(value: 'choyxona_owner', child: Text('Владельцы чайхан')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по имени или email...',
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

          // Список
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                var docs = snapshot.data!.docs;

                // Фильтрация по роли
                if (_filterRole != 'all') {
                  docs = docs.where((doc) {
                    final role = (doc.data() as Map)['role'] ?? 'client';
                    return role == _filterRole;
                  }).toList();
                }

                // Фильтрация по поиску
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map;
                    final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.toLowerCase();
                    final email = (data['email'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || email.contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final user = UserModel.fromFirestore(docs[index]);
                    return _buildUserCard(user, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
          child: user.photoUrl.isEmpty
              ? Text(
                  user.initials,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName.isNotEmpty ? user.fullName : 'Без имени',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ),
            _buildRoleBadge(user.role),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            // Choyxona nomi (admin va owner uchun)
            if ((user.role == 'choyxona_admin' || user.role == 'choyxona_owner') && user.choyxonaId != null) ...[
              const SizedBox(height: 4),
              FutureBuilder<String>(
                future: _getChoyxonaName(user.choyxonaId!),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? 'Yuklanmoqda...';
                  return Row(
                    children: [
                      Icon(Icons.restaurant, size: 12,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12,
                    color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd.MM.yyyy').format(user.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextLight : AppColors.textLight,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.book_online, size: 12,
                    color: isDark ? AppColors.darkTextLight : AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  '${user.totalBookings} broней',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextLight : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(user, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('Подробнее')),
            const PopupMenuItem(value: 'make_admin', child: Text('Назначить админом')),
            PopupMenuItem(
              value: user.isActive ? 'block' : 'unblock',
              child: Text(user.isActive ? 'Заблокировать' : 'Разблокировать'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    String text;

    switch (role) {
      case UserRole.superAdmin:
        color = Colors.red;
        text = 'Super Admin';
        break;
      case UserRole.choyxonaAdmin:
        color = Colors.purple;
        text = 'Админ';
        break;
      case UserRole.choyxonaOwner:
        color = Colors.orange;
        text = 'Владелец';
        break;
      default:
        color = AppColors.info;
        text = 'Клиент';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text('Нет пользователей', style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }

  /// Choyxona nomini olish (cache bilan)
  Future<String> _getChoyxonaName(String choyxonaId) async {
    // Cache dan tekshirish
    if (_choyxonaNames.containsKey(choyxonaId)) {
      return _choyxonaNames[choyxonaId]!;
    }
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('choyxonas')
          .doc(choyxonaId)
          .get();
      
      final name = doc.data()?['name'] as String? ?? 'Noma\'lum';
      _choyxonaNames[choyxonaId] = name;
      return name;
    } catch (e) {
      return 'Xato: $choyxonaId';
    }
  }

  Future<void> _handleUserAction(UserModel user, String action) async {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'make_admin':
        _showAssignAdminDialog(user);
        break;
      case 'block':
      case 'unblock':
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.userId)
            .update({'isActive': action == 'unblock'});
        break;
    }
  }

  void _showUserDetails(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                child: user.photoUrl.isEmpty
                    ? Text(user.initials, style: AppTextStyles.headlineLarge)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(user.fullName, style: AppTextStyles.headlineSmall),
              Text(user.email, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              _buildDetailRow('Телефон', user.phone.isNotEmpty ? user.phone : 'Не указан'),
              _buildDetailRow('Роль', user.getRoleDisplayName()),
              _buildDetailRow('Регистрация', DateFormat('dd.MM.yyyy HH:mm').format(user.createdAt)),
              _buildDetailRow('Всего броней', '${user.totalBookings}'),
              _buildDetailRow('Избранных', '${user.favoriteChoyxonas.length}'),
              _buildDetailRow('Статус', user.isActive ? 'Активен' : 'Заблокирован'),
              if (user.choyxonaId != null)
                FutureBuilder<String>(
                  future: _getChoyxonaName(user.choyxonaId!),
                  builder: (context, snapshot) {
                    return _buildDetailRow('Чайхана', snapshot.data ?? 'Yuklanmoqda...');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAssignAdminDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Назначить админом'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Назначить ${user.fullName} администратором чайханы?'),
            const SizedBox(height: 16),
            const Text(
              'Для назначения перейдите в раздел "Все чайханы" и выберите нужную чайхану.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}
