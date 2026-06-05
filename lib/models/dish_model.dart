import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель блюда
class DishModel {
  final String dishId;
  final String choyxonaId;
  final String name;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final String description;
  final String descriptionUz;
  final String descriptionRu;
  final String descriptionEn;
  final double price; // В сумах
  final String category; // 'main', 'appetizer', 'drink', 'dessert'
  final String imageUrl;
  final bool isAvailable;
  final bool isPopular;
  final bool isSpicy;
  final bool isVegetarian;
  final int preparationTime; // В минутах
  final int orderCount; // Количество заказов
  final double rating; // Средний рейтинг
  final int reviewCount;
  final List<String> allergens; // Аллергены
  final List<String> ingredients; // Ингредиенты
  final String unit; // Единица измерения: 'dona', 'kg', 'litr', 'porshon'
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Compatibility getter
  String get id => dishId;

  DishModel({
    required this.dishId,
    required this.choyxonaId,
    required this.name,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.description,
    required this.descriptionUz,
    required this.descriptionRu,
    required this.descriptionEn,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.isAvailable,
    required this.isPopular,
    required this.isSpicy,
    required this.isVegetarian,
    required this.preparationTime,
    required this.orderCount,
    required this.rating,
    required this.reviewCount,
    required this.allergens,
    required this.ingredients,
    this.unit = 'dona',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Получить название категории
  String get categoryName {
    switch (category) {
      case 'main':
        return 'Основные блюда';
      case 'appetizer':
        return 'Закуски';
      case 'drink':
        return 'Напитки';
      case 'dessert':
        return 'Десерты';
      default:
        return 'Другое';
    }
  }

  /// Получить иконку категории
  String get categoryIcon {
    switch (category) {
      case 'main':
        return '🍽️';
      case 'appetizer':
        return '🥗';
      case 'drink':
        return '🥤';
      case 'dessert':
        return '🍰';
      default:
        return '🍴';
    }
  }

  /// Форматированная цена
  String get formattedPrice {
    return '${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} сум';
  }

  /// Время приготовления в читаемом формате
  String get formattedPreparationTime {
    if (preparationTime < 60) {
      return '$preparationTime мин';
    } else {
      final hours = preparationTime ~/ 60;
      final minutes = preparationTime % 60;
      if (minutes == 0) {
        return '$hours ч';
      }
      return '$hours ч $minutes мин';
    }
  }

  /// Бейджи блюда
  List<String> get badges {
    final List<String> result = [];
    if (isPopular) result.add('Популярное');
    if (isSpicy) result.add('Острое');
    if (isVegetarian) result.add('Вегетарианское');
    if (isAvailable) result.add('Доступно');
    return result;
  }

  /// Валидация блюда
  static String? validateDish({
    required String name,
    required double price,
    required String category,
  }) {
    // Проверка названия
    if (name.trim().isEmpty) {
      return 'Введите название блюда';
    }

    if (name.trim().length < 2) {
      return 'Название должно содержать минимум 2 символа';
    }

    // Проверка цены
    if (price <= 0) {
      return 'Цена должна быть больше 0';
    }

    if (price > 10000000) {
      return 'Цена слишком большая';
    }

    // Проверка категории
    final validCategories = ['main', 'appetizer', 'drink', 'dessert'];
    if (!validCategories.contains(category)) {
      return 'Выберите категорию';
    }

    return null; // Всё ОК
  }

  /// Создать из Firestore документа
  factory DishModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DishModel(
      dishId: doc.id,
      choyxonaId: data['choyxonaId'] ?? '',
      name: data['name'] ?? data['nameRu'] ?? data['nameUz'] ?? data['nameEn'] ?? '',
      nameUz: data['nameUz'] ?? '',
      nameRu: data['nameRu'] ?? '',
      nameEn: data['nameEn'] ?? '',
      description: data['description'] ?? '',
      descriptionUz: data['descriptionUz'] ?? '',
      descriptionRu: data['descriptionRu'] ?? '',
      descriptionEn: data['descriptionEn'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? 'main',
      imageUrl: data['imageUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      isPopular: data['isPopular'] ?? false,
      isSpicy: data['isSpicy'] ?? false,
      isVegetarian: data['isVegetarian'] ?? false,
      preparationTime: data['preparationTime'] ?? 30,
      orderCount: data['orderCount'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      allergens: List<String>.from(data['allergens'] ?? []),
      ingredients: List<String>.from(data['ingredients'] ?? []),
      unit: data['unit'] ?? 'dona',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Конвертировать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'choyxonaId': choyxonaId,
      'name': name,
      'nameUz': nameUz,
      'nameRu': nameRu,
      'nameEn': nameEn,
      'description': description,
      'descriptionUz': descriptionUz,
      'descriptionRu': descriptionRu,
      'descriptionEn': descriptionEn,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'isSpicy': isSpicy,
      'isVegetarian': isVegetarian,
      'preparationTime': preparationTime,
      'orderCount': orderCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'allergens': allergens,
      'ingredients': ingredients,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Копировать с изменениями
  DishModel copyWith({
    String? choyxonaId,
    String? name,
    String? nameUz,
    String? nameRu,
    String? nameEn,
    String? description,
    String? descriptionUz,
    String? descriptionRu,
    String? descriptionEn,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    bool? isPopular,
    bool? isSpicy,
    bool? isVegetarian,
    int? preparationTime,
    int? orderCount,
    double? rating,
    int? reviewCount,
    List<String>? allergens,
    List<String>? ingredients,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DishModel(
      dishId: dishId,
      choyxonaId: choyxonaId ?? this.choyxonaId,
      name: name ?? this.name,
      nameUz: nameUz ?? this.nameUz,
      nameRu: nameRu ?? this.nameRu,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      descriptionUz: descriptionUz ?? this.descriptionUz,
      descriptionRu: descriptionRu ?? this.descriptionRu,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isPopular: isPopular ?? this.isPopular,
      isSpicy: isSpicy ?? this.isSpicy,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      preparationTime: preparationTime ?? this.preparationTime,
      orderCount: orderCount ?? this.orderCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      allergens: allergens ?? this.allergens,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
