import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран списка отзывов для владельца
class ReviewsListScreen extends StatelessWidget {
  final String? choyxonaId;

  const ReviewsListScreen({
    super.key,
    this.choyxonaId,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('reviews')
        .orderBy('createdAt', descending: true);

    if (choyxonaId != null) {
      query = query.where('choyxonaId', isEqualTo: choyxonaId);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('reviews'.tr()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
             return Center(
               child: Text('error'.tr() + ': ${snapshot.error}'),
             );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline,
                      size: 64, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text('no_reviews'.tr(),
                      style: AppTextStyles.bodyLarge),
                ],
              ),
            );
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              final rating = (data['rating'] ?? 0).toDouble();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              (data['userName'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['userName'] ?? 'Пользователь',
                                  style: AppTextStyles.titleSmall,
                                ),
                                Text(
                                  date != null 
                                      ? DateFormat('dd.MM.yyyy').format(date)
                                      : '',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                size: 16,
                                color: AppColors.starGold,
                              );
                            }),
                          ),
                        ],
                      ),
                      if (data['comment'] != null && data['comment'].isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          data['comment'],
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
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
