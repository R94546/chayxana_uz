import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель блюда в меню чайханы
class MenuItem {
  final String id;
  final String choyxonaId;
  final String name;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final String description;
  final String category; // appetizer, main, soup, salad, dessert, beverage
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final bool isPopular;
  final int preparationTime; // в минутах
  final List<String> ingredients;
  final DateTime createdAt;

  MenuItem({
    required this.id,
    required this.choyxonaId,
    required this.name,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.isPopular,
    required this.preparationTime,
    required this.ingredients,
    required this.createdAt,
  });

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      choyxonaId: data['choyxonaId'] ?? '',
      name: data['name'] ?? '',
      nameUz: data['nameUz'] ?? data['name'] ?? '',
      nameRu: data['nameRu'] ?? data['name'] ?? '',
      nameEn: data['nameEn'] ?? data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'main',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      isPopular: data['isPopular'] ?? false,
      preparationTime: data['preparationTime'] ?? 15,
      ingredients: List<String>.from(data['ingredients'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choyxonaId': choyxonaId,
      'name': name,
      'nameUz': nameUz,
      'nameRu': nameRu,
      'nameEn': nameEn,
      'description': description,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'preparationTime': preparationTime,
      'ingredients': ingredients,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Получить локализованное имя
  String getLocalizedName(String locale) {
    switch (locale) {
      case 'uz':
        return nameUz.isNotEmpty ? nameUz : name;
      case 'en':
        return nameEn.isNotEmpty ? nameEn : name;
      case 'ru':
      default:
        return nameRu.isNotEmpty ? nameRu : name;
    }
  }

  /// Получить название категории
  static String getCategoryName(String category, String locale) {
    final categories = {
      'appetizer': {'ru': 'Закуски', 'uz': "Gazaklar", 'en': 'Appetizers'},
      'main': {'ru': 'Основные блюда', 'uz': "Asosiy taomlar", 'en': 'Main dishes'},
      'soup': {'ru': 'Супы', 'uz': "Sho'rvalar", 'en': 'Soups'},
      'salad': {'ru': 'Салаты', 'uz': "Salatlar", 'en': 'Salads'},
      'dessert': {'ru': 'Десерты', 'uz': "Desertlar", 'en': 'Desserts'},
      'beverage': {'ru': 'Напитки', 'uz': "Ichimliklar", 'en': 'Beverages'},
    };
    return categories[category]?[locale] ?? category;
  }
}
