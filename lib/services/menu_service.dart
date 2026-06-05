import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/dish_model.dart';
import '../core/utils/error_handler.dart';

/// Сервис для работы с меню
class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Добавить блюдо
  Future<String?> addDish(DishModel dish) async {
    try {
      // Валидация
      final validationError = DishModel.validateDish(
        name: dish.name,
        price: dish.price,
        category: dish.category,
      );

      if (validationError != null) {
        return validationError;
      }

      // Создаём документ
      await _firestore.collection('dishes').add(dish.toMap());

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Обновить блюдо
  Future<String?> updateDish(String dishId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('dishes').doc(dishId).update(updates);

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Удалить блюдо
  Future<String?> deleteDish(String dishId) async {
    try {
      // Получаем блюдо для удаления фото
      final doc = await _firestore.collection('dishes').doc(dishId).get();
      
      if (doc.exists) {
        final dish = DishModel.fromFirestore(doc);
        
        // Удаляем фото из Storage если есть
        if (dish.imageUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(dish.imageUrl).delete();
          } catch (e) {
            // Игнорируем ошибку удаления фото
            ErrorHandler.logError(e, null);
          }
        }
      }

      // Удаляем документ
      await _firestore.collection('dishes').doc(dishId).delete();

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Получить все блюда чайханы
  Future<List<DishModel>> getDishesByChoyxona(String choyxonaId) async {
    try {
      final snapshot = await _firestore
          .collection('dishes')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .orderBy('category')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить блюда по категории
  Future<List<DishModel>> getDishesByCategory({
    required String choyxonaId,
    required String category,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('dishes')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить только доступные блюда
  Future<List<DishModel>> getAvailableDishes(String choyxonaId) async {
    try {
      final snapshot = await _firestore
          .collection('dishes')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .where('isAvailable', isEqualTo: true)
          .orderBy('category')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Переключить доступность блюда
  Future<String?> toggleAvailability(String dishId, bool isAvailable) async {
    try {
      await _firestore.collection('dishes').doc(dishId).update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Поиск блюд по названию
  Future<List<DishModel>> searchDishes({
    required String choyxonaId,
    required String query,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return getDishesByChoyxona(choyxonaId);
      }

      // Firestore не поддерживает полнотекстовый поиск
      // Загружаем все блюда и фильтруем локально
      final allDishes = await getDishesByChoyxona(choyxonaId);

      final lowerQuery = query.toLowerCase();

      return allDishes.where((dish) {
        final nameLower = dish.name.toLowerCase();
        final descriptionLower = dish.description.toLowerCase();

        return nameLower.contains(lowerQuery) ||
            descriptionLower.contains(lowerQuery);
      }).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Загрузить фото блюда
  Future<String?> uploadDishImage({
    required String choyxonaId,
    required String dishId,
    required File imageFile,
  }) async {
    try {
      // Создаём уникальное имя файла
      final fileName = 'dish_${dishId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'choyxonas/$choyxonaId/dishes/$fileName';

      // Загружаем файл
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(imageFile);

      // Получаем URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return null;
    }
  }

  /// Удалить фото блюда
  Future<void> deleteDishImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        await _storage.refFromURL(imageUrl).delete();
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
    }
  }

  /// Stream блюд чайханы (real-time)
  Stream<List<DishModel>> streamDishes(String choyxonaId) {
    return _firestore
        .collection('dishes')
        .where('choyxonaId', isEqualTo: choyxonaId)
        .orderBy('category')
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList());
  }

  /// Получить популярные блюда
  Future<List<DishModel>> getPopularDishes({
    required String choyxonaId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('dishes')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .where('isPopular', isEqualTo: true)
          .orderBy('orderCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Увеличить счётчик заказов блюда
  Future<void> incrementOrderCount(String dishId) async {
    try {
      await _firestore.collection('dishes').doc(dishId).update({
        'orderCount': FieldValue.increment(1),
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
    }
  }

  /// Получить блюдо по ID
  Future<DishModel?> getDishById(String dishId) async {
    try {
      final doc = await _firestore.collection('dishes').doc(dishId).get();

      if (!doc.exists) {
        return null;
      }

      return DishModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return null;
    }
  }

  /// Получить статистику меню
  Future<Map<String, dynamic>> getMenuStats(String choyxonaId) async {
    try {
      final dishes = await getDishesByChoyxona(choyxonaId);

      final totalDishes = dishes.length;
      final availableDishes = dishes.where((d) => d.isAvailable).length;
      final popularDishes = dishes.where((d) => d.isPopular).length;

      // Группировка по категориям
      final byCategory = <String, int>{};
      for (final dish in dishes) {
        byCategory[dish.category] = (byCategory[dish.category] ?? 0) + 1;
      }

      return {
        'totalDishes': totalDishes,
        'availableDishes': availableDishes,
        'unavailableDishes': totalDishes - availableDishes,
        'popularDishes': popularDishes,
        'byCategory': byCategory,
      };
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return {
        'totalDishes': 0,
        'availableDishes': 0,
        'unavailableDishes': 0,
        'popularDishes': 0,
        'byCategory': {},
      };
    }
  }
}
