import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion_model.dart';

/// 🎉 Сервис для работы с акциями и скидками
class PromotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Коллекция акций
  CollectionReference get _promotionsRef => _firestore.collection('promotions');

  /// Получить все активные акции
  Stream<List<Promotion>> getActivePromotions() {
    final now = DateTime.now();
    return _promotionsRef
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('endDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Promotion.fromFirestore(doc))
            .where((p) => p.startDate.isBefore(now)) // Дополнительная фильтрация
            .toList());
  }

  /// Получить акции конкретной чайханы
  Stream<List<Promotion>> getChoyxonaPromotions(String choyxonaId) {
    return _promotionsRef
        .where('choyxonaId', isEqualTo: choyxonaId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Promotion.fromFirestore(doc)).toList());
  }

  /// Получить активные акции чайханы
  Stream<List<Promotion>> getActiveChoyxonaPromotions(String choyxonaId) {
    final now = DateTime.now();
    return _promotionsRef
        .where('choyxonaId', isEqualTo: choyxonaId)
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Promotion.fromFirestore(doc))
            .where((p) => p.startDate.isBefore(now))
            .toList());
  }

  /// Создать акцию
  Future<String> createPromotion(Promotion promotion) async {
    final docRef = await _promotionsRef.add(promotion.toMap());
    return docRef.id;
  }

  /// Обновить акцию
  Future<void> updatePromotion(Promotion promotion) async {
    await _promotionsRef.doc(promotion.id).update({
      ...promotion.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Удалить акцию
  Future<void> deletePromotion(String promotionId) async {
    await _promotionsRef.doc(promotionId).delete();
  }

  /// Активировать/деактивировать акцию
  Future<void> togglePromotionStatus(String promotionId, bool isActive) async {
    await _promotionsRef.doc(promotionId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Проверить промокод
  Future<Promotion?> validatePromoCode(String choyxonaId, String promoCode) async {
    final now = DateTime.now();
    final snapshot = await _promotionsRef
        .where('choyxonaId', isEqualTo: choyxonaId)
        .where('promoCode', isEqualTo: promoCode.toUpperCase())
        .where('isActive', isEqualTo: true)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    
    final promotion = Promotion.fromFirestore(snapshot.docs.first);
    
    // Проверка дат
    if (now.isBefore(promotion.startDate) || now.isAfter(promotion.endDate)) {
      return null;
    }
    
    return promotion;
  }

  /// Получить одну акцию по ID
  Future<Promotion?> getPromotion(String promotionId) async {
    final doc = await _promotionsRef.doc(promotionId).get();
    if (!doc.exists) return null;
    return Promotion.fromFirestore(doc);
  }
}
