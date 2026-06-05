import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';

/// Модель отзыва
class Review {
  final String id;
  final String choyxonaId;
  final String userId;
  final String userName;
  final String userPhoto;
  final double rating;
  final String comment;
  final List<String> photos;
  final DateTime createdAt;
  final String? ownerResponse;
  final DateTime? responseDate;

  Review({
    required this.id,
    required this.choyxonaId,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.rating,
    required this.comment,
    required this.photos,
    required this.createdAt,
    this.ownerResponse,
    this.responseDate,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      choyxonaId: data['choyxonaId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'user'.tr(),
      userPhoto: data['userPhoto'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerResponse: data['ownerResponse'],
      responseDate: (data['responseDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choyxonaId': choyxonaId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerResponse': ownerResponse,
      'responseDate': responseDate,
    };
  }
}

/// Экран списка отзывов
class ReviewsScreen extends StatelessWidget {
  final String choyxonaId;
  final String choyxonaName;

  const ReviewsScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('reviews_title'.tr()),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Статистика
          _buildRatingStats(),

          // Список отзывов
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('choyxonaId', isEqualTo: choyxonaId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final reviews = snapshot.data!.docs
                    .map((doc) => Review.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return _ReviewCard(review: reviews[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddReviewScreen(
                choyxonaId: choyxonaId,
                choyxonaName: choyxonaName,
              ),
            ),
          );
        },
        icon: const Icon(Icons.rate_review),
        label: Text('leave_review'.tr()),
      ),
    );
  }

  Widget _buildRatingStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final reviews = snapshot.data!.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList();

        if (reviews.isEmpty) {
          return const SizedBox();
        }

        final avgRating = reviews.fold<double>(
          0,
              (sum, review) => sum + review.rating,
        ) /
            reviews.length;

        return Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.surface,
          child: Row(
            children: [
              // Средний рейтинг
              Column(
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.starGold,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < avgRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        color: AppColors.starGold,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reviews.length} ${'reviews_count'.tr()}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),

              const SizedBox(width: 32),

              // Распределение оценок
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final stars = 5 - index;
                    final count = reviews
                        .where((r) => r.rating.round() == stars)
                        .length;
                    final percent = count / reviews.length;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '$stars',
                            style: AppTextStyles.labelSmall,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: AppColors.starGold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.starGold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            count.toString(),
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'no_reviews'.tr(),
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'be_first_review'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка отзыва
class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка с пользователем
          Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                backgroundImage: review.userPhoto.isNotEmpty
                    ? NetworkImage(review.userPhoto)
                    : null,
                child: review.userPhoto.isEmpty
                    ? Text(
                  review.userName[0].toUpperCase(),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textWhite,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),

              // Имя и дата
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: AppTextStyles.titleMedium,
                    ),
                    Text(
                      DateFormat('d MMMM yyyy', 'ru').format(review.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Рейтинг
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.starGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.starGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.starGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Комментарий
          Text(
            review.comment,
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.5,
            ),
          ),

          // Фото (если есть)
          if (review.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.photos.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(review.photos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Ответ владельца (если есть)
          if (review.ownerResponse != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.store,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'owner_response'.tr(),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.ownerResponse!,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Экран добавления отзыва
class AddReviewScreen extends StatefulWidget {
  final String choyxonaId;
  final String choyxonaName;

  const AddReviewScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('leave_review'.tr()),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название чайханы
            Text(
              widget.choyxonaName,
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Выбор рейтинга
            Text(
              'your_rating'.tr(),
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = (index + 1).toDouble();
                      });
                    },
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 48,
                      color: AppColors.starGold,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Комментарий
            Text(
              'your_review'.tr(),
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'review_placeholder'.tr(),
              ),
            ),
            const SizedBox(height: 24),

            // Кнопка отправки
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.textWhite,
                    strokeWidth: 2,
                  ),
                )
                    : Text('submit_review'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('review_required'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await AuthService().getCurrentUserData();
      if (currentUser == null) {
        throw Exception('not_authorized'.tr());
      }

      final review = Review(
        id: '',
        choyxonaId: widget.choyxonaId,
        userId: currentUser.userId,
        userName: currentUser.fullName,
        userPhoto: currentUser.photoUrl,
        rating: _rating,
        comment: _commentController.text.trim(),
        photos: [],
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('reviews')
          .add(review.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('review_success'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}