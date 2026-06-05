import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../core/utils/error_handler.dart';

/// Сервис для работы с отзывами
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Добавить отзыв
  Future<String?> addReview(ReviewModel review) async {
    try {
      // Валидация
      final validationError = ReviewModel.validateReview(
        rating: review.rating,
        comment: review.comment,
      );

      if (validationError != null) {
        return validationError;
      }

      // Проверяем, есть ли уже отзыв от этого пользователя
      final existingReview = await _firestore
          .collection('reviews')
          .where('choyxonaId', isEqualTo: review.choyxonaId)
          .where('userId', isEqualTo: review.userId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        return 'Вы уже оставили отзыв для этой чайханы';
      }

      // Создаём отзыв
      await _firestore.collection('reviews').add(review.toMap());

      // Обновляем рейтинг чайханы
      await _updateChoyxonaRating(review.choyxonaId);

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Получить все отзывы чайханы
  Future<List<ReviewModel>> getReviewsByChoyxona(String choyxonaId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить отзывы пользователя
  Future<List<ReviewModel>> getReviewsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Добавить ответ владельца
  Future<String?> addOwnerResponse({
    required String reviewId,
    required String response,
  }) async {
    try {
      if (response.trim().isEmpty) {
        return 'Введите ответ';
      }

      if (response.trim().length < 5) {
        return 'Ответ должен содержать минимум 5 символов';
      }

      await _firestore.collection('reviews').doc(reviewId).update({
        'ownerResponse': response,
        'responseDate': FieldValue.serverTimestamp(),
      });

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Удалить отзыв
  Future<String?> deleteReview(String reviewId, String choyxonaId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();

      // Обновляем рейтинг чайханы
      await _updateChoyxonaRating(choyxonaId);

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Лайкнуть отзыв
  Future<String?> likeReview({
    required String reviewId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore.collection('reviews').doc(reviewId).get();

      if (!doc.exists) {
        return 'Отзыв не найден';
      }

      final review = ReviewModel.fromFirestore(doc);

      // Проверяем, уже лайкнул или нет
      if (review.likedBy.contains(userId)) {
        // Убираем лайк
        await _firestore.collection('reviews').doc(reviewId).update({
          'likedBy': FieldValue.arrayRemove([userId]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Добавляем лайк
        await _firestore.collection('reviews').doc(reviewId).update({
          'likedBy': FieldValue.arrayUnion([userId]),
          'likesCount': FieldValue.increment(1),
        });
      }

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Stream отзывов чайханы (real-time)
  Stream<List<ReviewModel>> streamReviews(String choyxonaId) {
    return _firestore
        .collection('reviews')
        .where('choyxonaId', isEqualTo: choyxonaId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
  }

  /// Получить статистику отзывов
  Future<Map<String, dynamic>> getReviewStats(String choyxonaId) async {
    try {
      final reviews = await getReviewsByChoyxona(choyxonaId);

      if (reviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          'positivePercentage': 0.0,
        };
      }

      return {
        'averageRating': ReviewModel.calculateAverageRating(reviews),
        'totalReviews': reviews.length,
        'distribution': ReviewModel.getRatingDistribution(reviews),
        'positivePercentage': ReviewModel.getPositivePercentage(reviews),
      };
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        'positivePercentage': 0.0,
      };
    }
  }

  /// Обновить рейтинг чайханы
  Future<void> _updateChoyxonaRating(String choyxonaId) async {
    try {
      final reviews = await getReviewsByChoyxona(choyxonaId);

      final averageRating = ReviewModel.calculateAverageRating(reviews);
      final reviewCount = reviews.length;

      await _firestore.collection('choyxonas').doc(choyxonaId).update({
        'rating': averageRating,
        'reviewCount': reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
    }
  }

  /// Проверить, может ли пользователь оставить отзыв
  Future<bool> canUserReview({
    required String userId,
    required String choyxonaId,
  }) async {
    try {
      // Проверяем, есть ли завершённое бронирование
      final bookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('choyxonaId', isEqualTo: choyxonaId)
          .where('status', isEqualTo: 'completed')
          .get();

      if (bookings.docs.isEmpty) {
        return false; // Нет завершённых бронирований
      }

      // Проверяем, есть ли уже отзыв
      final existingReview = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('choyxonaId', isEqualTo: choyxonaId)
          .get();

      return existingReview.docs.isEmpty; // Можно оставить, если нет отзыва
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return false;
    }
  }
}
