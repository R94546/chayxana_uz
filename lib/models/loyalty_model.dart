import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏆 Модель карты лояльности пользователя
class LoyaltyCard {
  final String id;
  final String userId;
  final String choyxonaId;
  final int points;
  final String tier; // bronze, silver, gold, platinum
  final int totalVisits;
  final double totalSpent;
  final DateTime createdAt;
  final DateTime? lastVisitAt;

  LoyaltyCard({
    required this.id,
    required this.userId,
    required this.choyxonaId,
    this.points = 0,
    this.tier = 'bronze',
    this.totalVisits = 0,
    this.totalSpent = 0,
    required this.createdAt,
    this.lastVisitAt,
  });

  /// Расчёт уровня на основе баллов
  static String calculateTier(int points) {
    if (points >= 100000) return 'platinum';
    if (points >= 50000) return 'gold';
    if (points >= 10000) return 'silver';
    return 'bronze';
  }

  /// Название уровня
  static String getTierName(String tier) {
    switch (tier) {
      case 'platinum': return 'Платина';
      case 'gold': return 'Золото';
      case 'silver': return 'Серебро';
      default: return 'Бронза';
    }
  }

  /// Цвет уровня
  static int getTierColor(String tier) {
    switch (tier) {
      case 'platinum': return 0xFFE5E4E2;
      case 'gold': return 0xFFFFD700;
      case 'silver': return 0xFFC0C0C0;
      default: return 0xFFCD7F32;
    }
  }

  /// Баллы до следующего уровня
  int get pointsToNextTier {
    if (tier == 'bronze') return 10000 - points;
    if (tier == 'silver') return 50000 - points;
    if (tier == 'gold') return 100000 - points;
    return 0; // Platinum - максимум
  }

  /// Прогресс до следующего уровня (0.0 - 1.0)
  double get progressToNextTier {
    if (tier == 'bronze') return points / 10000;
    if (tier == 'silver') return (points - 10000) / 40000;
    if (tier == 'gold') return (points - 50000) / 50000;
    return 1.0;
  }

  factory LoyaltyCard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoyaltyCard(
      id: doc.id,
      userId: data['userId'] ?? '',
      choyxonaId: data['choyxonaId'] ?? '',
      points: data['points'] ?? 0,
      tier: data['tier'] ?? 'bronze',
      totalVisits: data['totalVisits'] ?? 0,
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastVisitAt: (data['lastVisitAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'choyxonaId': choyxonaId,
      'points': points,
      'tier': tier,
      'totalVisits': totalVisits,
      'totalSpent': totalSpent,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastVisitAt': lastVisitAt != null ? Timestamp.fromDate(lastVisitAt!) : null,
    };
  }

  LoyaltyCard copyWith({
    String? id,
    String? userId,
    String? choyxonaId,
    int? points,
    String? tier,
    int? totalVisits,
    double? totalSpent,
    DateTime? createdAt,
    DateTime? lastVisitAt,
  }) {
    return LoyaltyCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      choyxonaId: choyxonaId ?? this.choyxonaId,
      points: points ?? this.points,
      tier: tier ?? this.tier,
      totalVisits: totalVisits ?? this.totalVisits,
      totalSpent: totalSpent ?? this.totalSpent,
      createdAt: createdAt ?? this.createdAt,
      lastVisitAt: lastVisitAt ?? this.lastVisitAt,
    );
  }
}

/// 🎁 Модель награды в программе лояльности
class LoyaltyReward {
  final String id;
  final String choyxonaId;
  final String name;
  final String description;
  final int pointsCost;
  final String? imageUrl;
  final bool isActive;
  final int? stockCount; // null = неограничено
  final DateTime createdAt;

  LoyaltyReward({
    required this.id,
    required this.choyxonaId,
    required this.name,
    required this.description,
    required this.pointsCost,
    this.imageUrl,
    this.isActive = true,
    this.stockCount,
    required this.createdAt,
  });

  factory LoyaltyReward.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoyaltyReward(
      id: doc.id,
      choyxonaId: data['choyxonaId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      pointsCost: data['pointsCost'] ?? 0,
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      stockCount: data['stockCount'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choyxonaId': choyxonaId,
      'name': name,
      'description': description,
      'pointsCost': pointsCost,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'stockCount': stockCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// 📜 История использования баллов
class LoyaltyTransaction {
  final String id;
  final String loyaltyCardId;
  final String type; // 'earn', 'redeem'
  final int points;
  final String description;
  final DateTime createdAt;

  LoyaltyTransaction({
    required this.id,
    required this.loyaltyCardId,
    required this.type,
    required this.points,
    required this.description,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoyaltyTransaction(
      id: doc.id,
      loyaltyCardId: data['loyaltyCardId'] ?? '',
      type: data['type'] ?? 'earn',
      points: data['points'] ?? 0,
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'loyaltyCardId': loyaltyCardId,
      'type': type,
      'points': points,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
