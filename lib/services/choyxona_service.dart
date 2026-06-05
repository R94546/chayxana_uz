import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/choyxona_model.dart';
import '../core/utils/error_handler.dart';

/// Сервис для работы с чайханами
class ChoyxonaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить все чайханы
  Future<List<Choyxona>> getAllChoyxonas() async {
    try {
      final snapshot = await _firestore
          .collection('choyxonas')
          .where('status', isEqualTo: 'active')
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs.map((doc) => Choyxona.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить чайхану по ID
  Future<Choyxona?> getChoyxonaById(String choyxonaId) async {
    try {
      final doc = await _firestore.collection('choyxonas').doc(choyxonaId).get();

      if (!doc.exists) {
        return null;
      }

      return Choyxona.fromFirestore(doc);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return null;
    }
  }

  /// Поиск чайхан по названию
  Future<List<Choyxona>> searchChoyxonas(String query) async {
    try {
      if (query.trim().isEmpty) {
        return getAllChoyxonas();
      }

      // Firestore не поддерживает полнотекстовый поиск, поэтому загружаем все и фильтруем локально
      final allChoyxonas = await getAllChoyxonas();

      final lowerQuery = query.toLowerCase();

      return allChoyxonas.where((choyxona) {
        final nameLower = choyxona.name.toLowerCase();
        final descriptionLower = choyxona.description.toLowerCase();
        final cityLower = choyxona.address.city.toLowerCase();
        final districtLower = choyxona.address.district.toLowerCase();

        return nameLower.contains(lowerQuery) ||
            descriptionLower.contains(lowerQuery) ||
            cityLower.contains(lowerQuery) ||
            districtLower.contains(lowerQuery);
      }).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Фильтровать по категории
  Future<List<Choyxona>> filterByCategory(String category) async {
    try {
      if (category == 'all' || category.isEmpty) {
        return getAllChoyxonas();
      }

      final snapshot = await _firestore
          .collection('choyxonas')
          .where('status', isEqualTo: 'active')
          .where('category', isEqualTo: category)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs.map((doc) => Choyxona.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить популярные чайханы
  Future<List<Choyxona>> getPopularChoyxonas({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('choyxonas')
          .where('status', isEqualTo: 'active')
          .where('isFeatured', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Choyxona.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить ближайшие чайханы (заглушка)
  Future<List<Choyxona>> getNearbyChoyxonas({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      // TODO: Реализовать геопоиск через GeoFlutterFire или аналог
      // Пока просто возвращаем все чайханы
      return getAllChoyxonas();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить открытые сейчас чайханы
  Future<List<Choyxona>> getOpenNowChoyxonas() async {
    try {
      final allChoyxonas = await getAllChoyxonas();

      return allChoyxonas.where((choyxona) => choyxona.isOpenNow()).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить чайханы владельца
  Future<List<Choyxona>> getChoyxonasByOwner(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('choyxonas')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Choyxona.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Создать новую чайхану
  Future<String?> createChoyxona(Choyxona choyxona) async {
    try {
      await _firestore.collection('choyxonas').add(choyxona.toMap());

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Обновить чайхану
  Future<String?> updateChoyxona(String choyxonaId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('choyxonas').doc(choyxonaId).update(updates);

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Удалить чайхану (мягкое удаление)
  Future<String?> deleteChoyxona(String choyxonaId) async {
    try {
      await _firestore.collection('choyxonas').doc(choyxonaId).update({
        'status': 'deleted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Stream всех чайхан (real-time)
  Stream<List<Choyxona>> streamChoyxonas() {
    return _firestore
        .collection('choyxonas')
        .where('status', isEqualTo: 'active')
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Choyxona.fromFirestore(doc)).toList());
  }

  /// Stream чайханы по ID (real-time)
  Stream<Choyxona?> streamChoyxonaById(String choyxonaId) {
    return _firestore
        .collection('choyxonas')
        .doc(choyxonaId)
        .snapshots()
        .map((doc) => doc.exists ? Choyxona.fromFirestore(doc) : null);
  }

  /// Фильтровать по ценовому диапазону
  Future<List<Choyxona>> filterByPriceRange(String priceRange) async {
    try {
      if (priceRange == 'all' || priceRange.isEmpty) {
        return getAllChoyxonas();
      }

      final snapshot = await _firestore
          .collection('choyxonas')
          .where('status', isEqualTo: 'active')
          .where('priceRange', isEqualTo: priceRange)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs.map((doc) => Choyxona.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Фильтровать по особенностям
  Future<List<Choyxona>> filterByFeatures(List<String> features) async {
    try {
      if (features.isEmpty) {
        return getAllChoyxonas();
      }

      final snapshot = await _firestore
          .collection('choyxonas')
          .where('status', isEqualTo: 'active')
          .where('features', arrayContainsAny: features)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs.map((doc) => Choyxona.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить топ чайханы по рейтингу
  Future<List<Choyxona>> getTopRatedChoyxonas({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('choyxonas')
          .where('status', isEqualTo: 'active')
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Choyxona.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить новые чайханы
  Future<List<Choyxona>> getNewChoyxonas({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('choyxonas')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Choyxona.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Увеличить счётчик просмотров
  Future<void> incrementViewCount(String choyxonaId) async {
    try {
      await _firestore.collection('choyxonas').doc(choyxonaId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
    }
  }
}
