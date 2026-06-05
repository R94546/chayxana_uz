import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/loyalty_model.dart';

/// 🏆 Сервис программы лояльности
class LoyaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _cardsRef => _firestore.collection('loyalty_cards');
  CollectionReference get _rewardsRef => _firestore.collection('loyalty_rewards');

  // ============ Карты лояльности ============

  /// Получить или создать карту лояльности пользователя
  Future<LoyaltyCard> getOrCreateCard(String userId, String choyxonaId) async {
    final query = await _cardsRef
        .where('userId', isEqualTo: userId)
        .where('choyxonaId', isEqualTo: choyxonaId)
        .limit(1)
        .get();
    
    if (query.docs.isNotEmpty) {
      return LoyaltyCard.fromFirestore(query.docs.first);
    }
    
    // Создаём новую карту
    final card = LoyaltyCard(
      id: '',
      userId: userId,
      choyxonaId: choyxonaId,
      createdAt: DateTime.now(),
    );
    
    final docRef = await _cardsRef.add(card.toMap());
    return card.copyWith(id: docRef.id);
  }

  /// Получить все карты пользователя
  Stream<List<LoyaltyCard>> getUserCards(String userId) {
    return _cardsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => LoyaltyCard.fromFirestore(d)).toList());
  }

  /// Начислить баллы
  Future<void> earnPoints({
    required String userId,
    required String choyxonaId,
    required int points,
    required String description,
    double? amountSpent,
  }) async {
    final card = await getOrCreateCard(userId, choyxonaId);
    
    final newPoints = card.points + points;
    final newTier = LoyaltyCard.calculateTier(newPoints);
    
    // Обновляем карту
    await _cardsRef.doc(card.id).update({
      'points': newPoints,
      'tier': newTier,
      'totalVisits': FieldValue.increment(1),
      'totalSpent': FieldValue.increment(amountSpent ?? 0),
      'lastVisitAt': FieldValue.serverTimestamp(),
    });
    
    // Записываем транзакцию
    await _cardsRef.doc(card.id).collection('transactions').add({
      'type': 'earn',
      'points': points,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Списать баллы
  Future<bool> redeemPoints({
    required String userId,
    required String choyxonaId,
    required int points,
    required String description,
  }) async {
    final card = await getOrCreateCard(userId, choyxonaId);
    
    if (card.points < points) return false;
    
    final newPoints = card.points - points;
    final newTier = LoyaltyCard.calculateTier(newPoints);
    
    await _cardsRef.doc(card.id).update({
      'points': newPoints,
      'tier': newTier,
    });
    
    await _cardsRef.doc(card.id).collection('transactions').add({
      'type': 'redeem',
      'points': -points,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return true;
  }

  /// История транзакций
  Stream<List<LoyaltyTransaction>> getTransactions(String cardId) {
    return _cardsRef
        .doc(cardId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) {
          final data = d.data();
          return LoyaltyTransaction(
            id: d.id,
            loyaltyCardId: cardId,
            type: data['type'] ?? 'earn',
            points: data['points'] ?? 0,
            description: data['description'] ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList());
  }

  // ============ Награды ============

  /// Получить награды чайханы
  Stream<List<LoyaltyReward>> getChoyxonaRewards(String choyxonaId) {
    return _rewardsRef
        .where('choyxonaId', isEqualTo: choyxonaId)
        .where('isActive', isEqualTo: true)
        .orderBy('pointsCost')
        .snapshots()
        .map((s) => s.docs.map((d) => LoyaltyReward.fromFirestore(d)).toList());
  }

  /// Создать награду
  Future<String> createReward(LoyaltyReward reward) async {
    final docRef = await _rewardsRef.add(reward.toMap());
    return docRef.id;
  }

  /// Обновить награду
  Future<void> updateReward(LoyaltyReward reward) async {
    await _rewardsRef.doc(reward.id).update(reward.toMap());
  }

  /// Удалить награду
  Future<void> deleteReward(String rewardId) async {
    await _rewardsRef.doc(rewardId).delete();
  }

  /// Получить награду (обменять баллы)
  Future<bool> claimReward({
    required String userId,
    required String choyxonaId,
    required LoyaltyReward reward,
  }) async {
    final card = await getOrCreateCard(userId, choyxonaId);
    
    if (card.points < reward.pointsCost) return false;
    
    // Проверяем наличие
    if (reward.stockCount != null && reward.stockCount! <= 0) return false;
    
    // Списываем баллы
    final success = await redeemPoints(
      userId: userId,
      choyxonaId: choyxonaId,
      points: reward.pointsCost,
      description: 'Награда: ${reward.name}',
    );
    
    if (!success) return false;
    
    // Уменьшаем остаток если есть лимит
    if (reward.stockCount != null) {
      await _rewardsRef.doc(reward.id).update({
        'stockCount': FieldValue.increment(-1),
      });
    }
    
    return true;
  }
}
