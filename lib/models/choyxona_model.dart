import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель данных для чайханы
class Choyxona {
  final String id;
  final String name;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final String description;
  final List<String> images;
  final String mainImage;
  final String category;
  final List<String> cuisine;
  final ChoyxonaAddress address;
  final ChoyxonaContacts contacts;
  final Map<String, WorkingHours> workingHours;
  final List<String> features;
  final String priceRange;
  final int capacity;
  final int roomCount; // Количество xonalar (комнат)
  final double rating;
  final int reviewCount;
  final int bookingCount;
  final String ownerId;
  final List<String> adminIds;
  final String status;
  final bool isVerified;
  final bool isFeatured;
  final int? sortOrder; // NEW: for custom ordering
  final DateTime createdAt;
  final DateTime updatedAt;

  Choyxona({
    required this.id,
    required this.name,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.description,
    required this.images,
    required this.mainImage,
    required this.category,
    required this.cuisine,
    required this.address,
    required this.contacts,
    required this.workingHours,
    required this.features,
    required this.priceRange,
    required this.capacity,
    required this.roomCount,
    required this.rating,
    required this.reviewCount,
    required this.bookingCount,
    required this.ownerId,
    required this.adminIds,
    required this.status,
    required this.isVerified,
    required this.isFeatured,
    this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из Firestore документа
  factory Choyxona.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Choyxona(
      id: doc.id,
      name: data['name'] ?? '',
      nameUz: data['nameUz'] ?? '',
      nameRu: data['nameRu'] ?? '',
      nameEn: data['nameEn'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      mainImage: data['mainImage'] ?? '',
      category: data['category'] ?? '',
      cuisine: List<String>.from(data['cuisine'] ?? []),
      address: ChoyxonaAddress.fromMap(data['address'] ?? {}),
      contacts: ChoyxonaContacts.fromMap(data['contacts'] ?? {}),
      workingHours: (data['workingHours'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, WorkingHours.fromMap(value)),
      ) ?? {},
      features: List<String>.from(data['features'] ?? []),
      priceRange: data['priceRange'] ?? '\$\$',
      capacity: data['capacity'] ?? 0,
      roomCount: data['roomCount'] ?? data['tableCount'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      bookingCount: data['bookingCount'] ?? 0,
      ownerId: data['ownerId'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      status: data['status'] ?? 'active',
      isVerified: data['isVerified'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      sortOrder: data['sortOrder'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Конвертировать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameUz': nameUz,
      'nameRu': nameRu,
      'nameEn': nameEn,
      'description': description,
      'images': images,
      'mainImage': mainImage,
      'category': category,
      'cuisine': cuisine,
      'address': address.toMap(),
      'contacts': contacts.toMap(),
      'workingHours': workingHours.map((key, value) => MapEntry(key, value.toMap())),
      'features': features,
      'priceRange': priceRange,
      'capacity': capacity,
      'roomCount': roomCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'bookingCount': bookingCount,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'status': status,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Проверка открыта ли чайхана сейчас
  bool isOpenNow() {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    
    // Если рабочие часы не заданы, используем дефолтные значения (09:00 - 23:00)
    WorkingHours? hours = workingHours[dayName];
    if (workingHours.isEmpty) {
      hours = WorkingHours(open: '09:00', close: '23:00', isOpen: true);
    }

    if (hours == null || !hours.isOpen) return false;

    final currentTime = TimeOfDay.now();
    final openTime = _parseTime(hours.open);
    final closeTime = _parseTime(hours.close);

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;

    if (closeMinutes < openMinutes) {
      // Работает через полночь
      return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
    } else {
      return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
    }
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Получить расстояние до чайханы (заглушка)
  String getDistance() {
    // TODO: Реализовать расчёт реального расстояния через geolocator
    return '2.5 км';
  }
}

/// Адрес чайханы
class ChoyxonaAddress {
  final String street;
  final String city;
  final String district;
  final String region;
  final String country;
  final String postalCode;
  final double latitude;
  final double longitude;

  ChoyxonaAddress({
    required this.street,
    required this.city,
    required this.district,
    required this.region,
    required this.country,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });

  factory ChoyxonaAddress.fromMap(Map<String, dynamic> map) {
    return ChoyxonaAddress(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      region: map['region'] ?? '',
      country: map['country'] ?? '',
      postalCode: map['postalCode'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'district': district,
      'region': region,
      'country': country,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get fullAddress => '$street, $city';
  String get shortAddress => '$district, $city';
}

/// Контакты чайханы
class ChoyxonaContacts {
  final String phone;
  final String email;
  final String website;
  final String instagram;
  final String telegram;

  ChoyxonaContacts({
    required this.phone,
    required this.email,
    required this.website,
    required this.instagram,
    required this.telegram,
  });

  factory ChoyxonaContacts.fromMap(Map<String, dynamic> map) {
    return ChoyxonaContacts(
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      instagram: map['instagram'] ?? '',
      telegram: map['telegram'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
      'website': website,
      'instagram': instagram,
      'telegram': telegram,
    };
  }
}

/// Рабочие часы
class WorkingHours {
  final String open;
  final String close;
  final bool isOpen;

  WorkingHours({
    required this.open,
    required this.close,
    required this.isOpen,
  });

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      open: map['open'] ?? '08:00',
      close: map['close'] ?? '23:00',
      isOpen: map['isOpen'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'open': open,
      'close': close,
      'isOpen': isOpen,
    };
  }

  String get timeRange => '$open - $close';
}