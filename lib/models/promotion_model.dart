import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎉 Модель акции/скидки
class Promotion {
  final String id;
  final String choyxonaId;
  final String title;
  final String description;
  final int discountPercent;
  final DateTime startDate;
  final DateTime endDate;
  final String? promoCode;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Promotion({
    required this.id,
    required this.choyxonaId,
    required this.title,
    required this.description,
    required this.discountPercent,
    required this.startDate,
    required this.endDate,
    this.promoCode,
    this.isActive = true,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Проверка активности акции
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Количество дней до окончания
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Создание из Firestore документа
  factory Promotion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Promotion(
      id: doc.id,
      choyxonaId: data['choyxonaId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      discountPercent: data['discountPercent'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      promoCode: data['promoCode'],
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Преобразование в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'choyxonaId': choyxonaId,
      'title': title,
      'description': description,
      'discountPercent': discountPercent,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'promoCode': promoCode,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Копирование с изменениями
  Promotion copyWith({
    String? id,
    String? choyxonaId,
    String? title,
    String? description,
    int? discountPercent,
    DateTime? startDate,
    DateTime? endDate,
    String? promoCode,
    bool? isActive,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Promotion(
      id: id ?? this.id,
      choyxonaId: choyxonaId ?? this.choyxonaId,
      title: title ?? this.title,
      description: description ?? this.description,
      discountPercent: discountPercent ?? this.discountPercent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      promoCode: promoCode ?? this.promoCode,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
