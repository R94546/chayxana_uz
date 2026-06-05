import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран отзывов чайханы для админа
class ChoyxonaReviewsScreen extends StatelessWidget {
  final String choyxonaId;

  const ChoyxonaReviewsScreen({super.key, required this.choyxonaId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Отзывы'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('choyxonaId', isEqualTo: choyxonaId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          final reviews = snapshot.data!.docs;

          // Рассчитать средний рейтинг
          double avgRating = 0;
          for (final doc in reviews) {
            avgRating += (doc.data() as Map)['rating'] ?? 0;
          }
          avgRating = avgRating / reviews.length;

          return Column(
            children: [
              // Общая статистика
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              avgRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Средний рейтинг',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 50, color: Colors.white24),
                    Column(
                      children: [
                        Text(
                          '${reviews.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Всего отзывов',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Список отзывов
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final data = reviews[index].data() as Map<String, dynamic>;
                    return _buildReviewCard(context, reviews[index].id, data, isDark);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, String id, Map<String, dynamic> data, bool isDark) {
    final rating = (data['rating'] as num?)?.toDouble() ?? 0;
    final comment = data['comment'] ?? '';
    final userId = data['userId'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final reply = data['reply'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Автор
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, snapshot) {
                final name = snapshot.hasData
                    ? '${snapshot.data?.get('firstName') ?? ''} ${snapshot.data?.get('lastName') ?? ''}'
                    : 'Гость';

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        name.trim().isNotEmpty ? name[0].toUpperCase() : 'Г',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.trim().isEmpty ? 'Гость' : name,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              DateFormat('dd.MM.yyyy').format(createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Рейтинг
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: AppColors.starGold,
                        size: 18,
                      )),
                    ),
                  ],
                );
              },
            ),

            // Комментарий
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],

            // Ответ чайханы
            if (reply != null && reply.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Ответ чайханы',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(reply),
                  ],
                ),
              ),
            ],

            // Кнопка ответа
            if (reply == null || reply.isEmpty) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _showReplyDialog(context, id),
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('Ответить'),
              ),
            ],
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
          Icon(Icons.star_border, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text('Нет отзывов', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Отзывы появятся после посещений',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, String reviewId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ответить на отзыв'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Напишите ваш ответ...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              await FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(reviewId)
                  .update({'reply': controller.text.trim()});

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ответ добавлен'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}
