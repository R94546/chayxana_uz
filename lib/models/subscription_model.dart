import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель подписки чайханы
class Subscription {
  final String id;
  final String choyxonaId;
  final String plan; // 'free', 'premium'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final double price;
  final String paymentStatus; // 'pending', 'paid', 'failed', 'cancelled'
  final bool isTrial;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.choyxonaId,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.price,
    required this.paymentStatus,
    required this.isTrial,
    required this.createdAt,
  });

  /// Подписка активна
  bool get isActiveNow => isActive && DateTime.now().isBefore(endDate);
  
  /// Осталось дней
  int get daysLeft => endDate.difference(DateTime.now()).inDays;
  
  /// Истекает скоро (менее 7 дней)
  bool get isExpiringSoon => daysLeft <= 7 && daysLeft > 0;

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      choyxonaId: data['choyxonaId'] ?? '',
      plan: data['plan'] ?? 'free',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? false,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      paymentStatus: data['paymentStatus'] ?? 'pending',
      isTrial: data['isTrial'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choyxonaId': choyxonaId,
      'plan': plan,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'price': price,
      'paymentStatus': paymentStatus,
      'isTrial': isTrial,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Создать пробную подписку на 7 дней
  static Subscription createTrial(String choyxonaId) {
    final now = DateTime.now();
    return Subscription(
      id: '',
      choyxonaId: choyxonaId,
      plan: 'premium',
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      isActive: true,
      price: 0,
      paymentStatus: 'paid',
      isTrial: true,
      createdAt: now,
    );
  }

  /// Создать платную подписку на 30 дней
  static Subscription createPremium(String choyxonaId) {
    final now = DateTime.now();
    return Subscription(
      id: '',
      choyxonaId: choyxonaId,
      plan: 'premium',
      startDate: now,
      endDate: now.add(const Duration(days: 30)),
      isActive: true,
      price: 300000, // 300,000 сум
      paymentStatus: 'pending',
      isTrial: false,
      createdAt: now,
    );
  }
}
