import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'edit_choyxona_screen.dart';

/// Экран списка чайхан для владельца
class ChoyxonasListScreen extends StatelessWidget {
  const ChoyxonasListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('choyxonas'.tr()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('choyxonas')
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
                  Icon(Icons.restaurant_outlined,
                      size: 64, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text('no_choyxonas'.tr(),
                      style: AppTextStyles.bodyLarge),
                ],
              ),
            );
          }

          final choyxonas = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: choyxonas.length,
            itemBuilder: (context, index) {
              final doc = choyxonas[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditChoyxonaScreen(
                        choyxonaId: doc.id,
                        choyxonaData: data,
                      ),
                    ),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: data['mainImage'] != null && data['mainImage'].isNotEmpty
                        ? Image.network(
                            data['mainImage'],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.restaurant, color: AppColors.primary),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.restaurant, color: AppColors.primary),
                          ),
                  ),
                  title: Text(data['name'] ?? 'no_name'.tr()),
                  subtitle: Text(
                    data['address']?['city'] ?? '',
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: data['status'] == 'active' 
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          data['status'] == 'active' ? 'active'.tr() : 'inactive'.tr(),
                          style: TextStyle(
                            color: data['status'] == 'active' 
                                ? AppColors.success 
                                : AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
