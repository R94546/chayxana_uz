import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/error_handler.dart';

/// Сервис для управления избранными чайханами
class FavoritesService {
  final _firestore = FirebaseFirestore.instance;

  /// Добавить/убрать чайхану из избранного
  Future<bool> toggleFavorite(String userId, String choyxonaId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return false;

      final favorites = List<String>.from(userDoc.data()?['favoriteChoyxonas'] ?? []);

      if (favorites.contains(choyxonaId)) {
        favorites.remove(choyxonaId);
      } else {
        favorites.add(choyxonaId);
      }

      await userRef.update({
        'favoriteChoyxonas': favorites,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return favorites.contains(choyxonaId);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return false;
    }
  }

  /// Проверить, находится ли чайхана в избранном
  Future<bool> isFavorite(String userId, String choyxonaId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final favorites = List<String>.from(userDoc.data()?['favoriteChoyxonas'] ?? []);
      return favorites.contains(choyxonaId);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return false;
    }
  }

  /// Получить все избранные чайханы
  Stream<List<String>> getFavorites(String userId) {
    debugPrint('DEBUG FavoritesService: Getting favorites for user: $userId');
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        debugPrint('DEBUG FavoritesService: User document does not exist');
        return <String>[];
      }
      final data = doc.data();
      final favorites = List<String>.from(data?['favoriteChoyxonas'] ?? []);
      debugPrint('DEBUG FavoritesService: Found ${favorites.length} favorites: $favorites');
      return favorites;
    });
  }
}