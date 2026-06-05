import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

/// Экран назначения админа для чайханы (Super Admin)
class AssignAdminScreen extends StatefulWidget {
  final String choyxonaId;
  final String choyxonaName;
  final String choyxonaAddress;

  const AssignAdminScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaName,
    this.choyxonaAddress = '',
  });

  @override
  State<AssignAdminScreen> createState() => _AssignAdminScreenState();
}

class _AssignAdminScreenState extends State<AssignAdminScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel> _currentAdmins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentAdmins();
  }

  Future<void> _loadCurrentAdmins() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .get();

      setState(() {
        _currentAdmins = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading admins: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Назначить админа'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Информация о чайхане
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.restaurant, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.choyxonaName,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                            if (widget.choyxonaAddress.isNotEmpty)
                              Text(
                                widget.choyxonaAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Текущие админы
                if (_currentAdmins.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Текущие администраторы',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_currentAdmins.length}/2',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._currentAdmins.map((admin) => _buildAdminTile(admin, isDark)),
                  const Divider(height: 32),
                ],

                // Заголовок поиска
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Доступные пользователи',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Поиск пользователей
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск по email или имени...',
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
                const SizedBox(height: 8),

                // Список пользователей для назначения
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    // Получаем всех пользователей, кроме superadmin
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .limit(100)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text('Нет доступных пользователей'),
                            ],
                          ),
                        );
                      }

                      var users = snapshot.data!.docs
                          .map((doc) => UserModel.fromFirestore(doc))
                          // Исключаем superadmin и уже назначенных на эту чайхану
                          .where((user) => 
                              user.role != UserRole.superAdmin &&
                              !_currentAdmins.any((a) => a.userId == user.userId) &&
                              (user.choyxonaId == null || user.choyxonaId!.isEmpty || user.choyxonaId == widget.choyxonaId))
                          .toList();

                      // Фильтрация по поиску
                      if (_searchQuery.isNotEmpty) {
                        users = users.where((user) {
                          return user.email.toLowerCase().contains(_searchQuery) ||
                              user.fullName.toLowerCase().contains(_searchQuery);
                        }).toList();
                      }

                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(_searchQuery.isNotEmpty 
                                  ? 'Пользователи не найдены' 
                                  : 'Все пользователи уже назначены'),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: users.length,
                        itemBuilder: (context, index) => _buildUserTile(users[index], isDark),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAdminTile(UserModel admin, bool isDark) {
    final isOwner = admin.role == UserRole.choyxonaOwner;
    final roleColor = isOwner ? Colors.orange : Colors.purple;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roleColor.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.1),
          backgroundImage: admin.photoUrl.isNotEmpty ? NetworkImage(admin.photoUrl) : null,
          child: admin.photoUrl.isEmpty
              ? Text(admin.initials, style: TextStyle(color: roleColor, fontWeight: FontWeight.bold))
              : null,
        ),
        title: Text(
          admin.fullName.isNotEmpty ? admin.fullName : admin.email,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isOwner ? 'Владелец' : 'Админ',
                style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                admin.email,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: AppColors.error),
          onPressed: () => _removeAdmin(admin),
          tooltip: 'Удалить из администраторов',
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user, bool isDark) {
    // Определяем текущую роль для отображения
    String currentRole = 'Клиент';
    Color roleColor = Colors.blue;
    
    if (user.role == UserRole.choyxonaOwner) {
      currentRole = 'Владелец (другой)';
      roleColor = Colors.orange;
    } else if (user.role == UserRole.choyxonaAdmin) {
      currentRole = 'Админ (другой)';
      roleColor = Colors.purple;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
          child: user.photoUrl.isEmpty
              ? Text(user.initials, style: TextStyle(color: Theme.of(context).primaryColor))
              : null,
        ),
        title: Text(
          user.fullName.isNotEmpty ? user.fullName : 'Без имени',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                currentRole,
                style: TextStyle(fontSize: 10, color: roleColor),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (role) => _assignRole(user, role),
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Назначить',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: UserRole.choyxonaAdmin,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.purple, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Администратор', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Полное управление', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: UserRole.choyxonaOwner,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.store, color: Colors.orange, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Владелец', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Только просмотр', style: TextStyle(fontSize: 11, color: Colors.grey)),
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

  Future<void> _assignRole(UserModel user, String role) async {
    if (_currentAdmins.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Максимум 2 администратора на чайхану'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final currentUser = await AuthService().getCurrentUserData();
      
      await FirebaseFirestore.instance.collection('users').doc(user.userId).update({
        'role': role,
        'choyxonaId': widget.choyxonaId,
        'assignedBy': currentUser?.userId,
        'assignedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        final roleName = role == UserRole.choyxonaAdmin ? 'администратором' : 'владельцем';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName.isNotEmpty ? user.fullName : user.email} назначен $roleName'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadCurrentAdmins();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _removeAdmin(UserModel admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить администратора?'),
        content: Text('Убрать ${admin.fullName.isNotEmpty ? admin.fullName : admin.email} из администраторов чайханы?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(admin.userId).update({
          'role': UserRole.client,
          'choyxonaId': null,
          'assignedBy': null,
          'assignedAt': null,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Администратор удалён'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadCurrentAdmins();
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
