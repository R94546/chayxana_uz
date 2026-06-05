import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель отзыва
class ReviewModel {
  final String reviewId;
  final String choyxonaId;
  final String userId;
  final String userName;
  final String userPhoto;
  final double rating; // 1.0 - 5.0
  final String comment;
  final List<String> photos;
  final DateTime createdAt;
  final String? ownerResponse;
  final DateTime? responseDate;
  final int likesCount;
  final List<String> likedBy;
  final bool isVerified; // Проверенное бронирование

  ReviewModel({
    required this.reviewId,
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
    required this.likesCount,
    required this.likedBy,
    required this.isVerified,
  });

  /// Есть ли ответ владельца
  bool get hasOwnerResponse => ownerResponse != null && ownerResponse!.isNotEmpty;

  /// Есть ли фотографии
  bool get hasPhotos => photos.isNotEmpty;

  /// Получить рейтинг в звёздах (целое число)
  int get starsCount => rating.round();

  /// Получить текст рейтинга
  String get ratingText {
    if (rating >= 4.5) return 'Отлично';
    if (rating >= 3.5) return 'Хорошо';
    if (rating >= 2.5) return 'Нормально';
    if (rating >= 1.5) return 'Плохо';
    return 'Ужасно';
  }

  /// Получить эмодзи рейтинга
  String get ratingEmoji {
    if (rating >= 4.5) return '😍';
    if (rating >= 3.5) return '😊';
    if (rating >= 2.5) return '😐';
    if (rating >= 1.5) return '😞';
    return '😡';
  }

  /// Форматированная дата
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Только что';
        }
        return '${difference.inMinutes} мин. назад';
      }
      return '${difference.inHours} ч. назад';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks нед. назад';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months мес. назад';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years г. назад';
    }
  }

  /// Валидация отзыва
  static String? validateReview({
    required double rating,
    required String comment,
  }) {
    // Проверка рейтинга
    if (rating < 1.0 || rating > 5.0) {
      return 'Рейтинг должен быть от 1 до 5';
    }

    // Проверка комментария
    if (comment.trim().isEmpty) {
      return 'Напишите комментарий';
    }

    if (comment.trim().length < 10) {
      return 'Комментарий должен содержать минимум 10 символов';
    }

    if (comment.trim().length > 500) {
      return 'Комментарий не должен превышать 500 символов';
    }

    return null; // Всё ОК
  }

  /// Вычислить средний рейтинг из списка отзывов
  static double calculateAverageRating(List<ReviewModel> reviews) {
    if (reviews.isEmpty) return 0.0;

    final sum = reviews.fold<double>(0.0, (sum, review) => sum + review.rating);
    return sum / reviews.length;
  }

  /// Получить распределение рейтингов
  static Map<int, int> getRatingDistribution(List<ReviewModel> reviews) {
    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final review in reviews) {
      final stars = review.starsCount;
      distribution[stars] = (distribution[stars] ?? 0) + 1;
    }

    return distribution;
  }

  /// Получить процент положительных отзывов (4-5 звёзд)
  static double getPositivePercentage(List<ReviewModel> reviews) {
    if (reviews.isEmpty) return 0.0;

    final positiveCount = reviews.where((r) => r.rating >= 4.0).length;
    return (positiveCount / reviews.length) * 100;
  }

  /// Создать из Firestore документа
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ReviewModel(
      reviewId: doc.id,
      choyxonaId: data['choyxonaId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhoto: data['userPhoto'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerResponse: data['ownerResponse'],
      responseDate: (data['responseDate'] as Timestamp?)?.toDate(),
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isVerified: data['isVerified'] ?? false,
    );
  }

  /// Конвертировать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'choyxonaId': choyxonaId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerResponse': ownerResponse,
      'responseDate': responseDate != null ? Timestamp.fromDate(responseDate!) : null,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'isVerified': isVerified,
    };
  }

  /// Копировать с изменениями
  ReviewModel copyWith({
    String? choyxonaId,
    String? userId,
    String? userName,
    String? userPhoto,
    double? rating,
    String? comment,
    List<String>? photos,
    DateTime? createdAt,
    String? ownerResponse,
    DateTime? responseDate,
    int? likesCount,
    List<String>? likedBy,
    bool? isVerified,
  }) {
    return ReviewModel(
      reviewId: reviewId,
      choyxonaId: choyxonaId ?? this.choyxonaId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      ownerResponse: ownerResponse ?? this.ownerResponse,
      responseDate: responseDate ?? this.responseDate,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
