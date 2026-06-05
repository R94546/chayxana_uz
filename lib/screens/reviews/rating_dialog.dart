import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Диалог обязательного рейтинга (как в Yandex Taxi)
/// Появляется после оплаты, пропустить нельзя
class RatingDialog extends StatefulWidget {
  final String bookingId;
  final String choyxonaId;
  final String choyxonaName;
  final String userId;

  const RatingDialog({
    super.key,
    required this.bookingId,
    required this.choyxonaId,
    required this.choyxonaName,
    required this.userId,
  });

  /// Показать диалог рейтинга (нельзя закрыть без оценки)
  static Future<void> show(BuildContext context, {
    required String bookingId,
    required String choyxonaId,
    required String choyxonaName,
    required String userId,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Нельзя закрыть тапом вне
      builder: (context) => PopScope(
        canPop: false, // Нельзя закрыть кнопкой назад
        child: RatingDialog(
          bookingId: bookingId,
          choyxonaId: choyxonaId,
          choyxonaName: choyxonaName,
          userId: userId,
        ),
      ),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> with SingleTickerProviderStateMixin {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Иконка успеха
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Заголовок
                Text(
                  'Rahmat! 🎉',
                  style: AppTextStyles.headlineMedium,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Choyxonani baholang',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  widget.choyxonaName,
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Звёзды рейтинга
                _buildStarRating(),
                
                const SizedBox(height: 24),
                
                // Текстовое поле для отзыва
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Fikringizni yozing (ixtiyoriy)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Кнопка отправки
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _rating > 0 ? 'Yuborish' : 'Yulduz tanlang',
                            style: AppTextStyles.button,
                          ),
                  ),
                ),
                
                if (_rating == 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '⚠️ Baholash majburiy',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= _rating;
        
        return GestureDetector(
          onTap: () => setState(() => _rating = starIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              size: 44,
              color: isSelected ? Colors.amber : AppColors.textLight,
            ),
          ),
        );
      }),
    );
  }

  Future<void> _submitRating() async {
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);

    try {
      // Создаём отзыв
      await FirebaseFirestore.instance.collection('reviews').add({
        'userId': widget.userId,
        'choyxonaId': widget.choyxonaId,
        'bookingId': widget.bookingId,
        'rating': _rating,
        'comment': _reviewController.text.trim(),
        'isVerified': true, // Подтверждённый (через бронирование)
        'ownerReply': null,
        'ownerReplyAt': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Помечаем бронирование как оценённое
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'isRated': true});

      // Обновляем рейтинг чайханы
      await _updateChoyxonaRating();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharhingiz uchun rahmat! ⭐'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xatolik yuz berdi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateChoyxonaRating() async {
    try {
      // Получаем все отзывы чайханы
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      // Вычисляем средний рейтинг
      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
      }
      final averageRating = totalRating / reviewsSnapshot.docs.length;

      // Обновляем чайхану
      await FirebaseFirestore.instance
          .collection('choyxonas')
          .doc(widget.choyxonaId)
          .update({
        'rating': double.parse(averageRating.toStringAsFixed(1)),
        'reviewCount': reviewsSnapshot.docs.length,
      });
    } catch (e) {
      debugPrint('Error updating choyxona rating: $e');
    }
  }
}
