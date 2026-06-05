import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран списка зарегистрированных пользователей
class ClientsListScreen extends StatelessWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('registered_users'.tr()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
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
                  Icon(Icons.people_outline,
                      size: 64, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text('no_clients'.tr(),
                      style: AppTextStyles.bodyLarge),
                ],
              ),
            );
          }

          final clients = snapshot.data!.docs;

          return Column(
            children: [
              // Статистика
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'total_users'.tr() + ': ${clients.length}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final data = clients[index].data() as Map<String, dynamic>;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final role = data['role'] ?? 'user';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(role).withOpacity(0.1),
                          backgroundImage: data['photoUrl'] != null && data['photoUrl'].isNotEmpty
                              ? NetworkImage(data['photoUrl'])
                              : null,
                          child: data['photoUrl'] == null || data['photoUrl'].isEmpty
                              ? Text(
                                  (data['fullName'] ?? data['email'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(color: _getRoleColor(role)),
                                )
                              : null,
                        ),
                        title: Text(data['fullName'] ?? data['email'] ?? 'unknown_user'.tr()),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['email'] ?? data['phone'] ?? '',
                              style: AppTextStyles.bodySmall,
                            ),
                            if (createdAt != null)
                              Text(
                                'registered'.tr() + ': ${DateFormat('dd.MM.yyyy').format(createdAt)}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRoleColor(role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getRoleLabel(role),
                            style: TextStyle(
                              color: _getRoleColor(role),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return AppColors.accent;
      case 'admin':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Владелец';
      case 'admin':
        return 'Админ';
      default:
        return 'Клиент';
    }
  }
}
