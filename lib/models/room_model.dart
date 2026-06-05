import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель комнаты/отдельного помещения в чайхане
class RoomModel {
  final String id;
  final String choyxonaId;
  final String number; // Номер комнаты (например: "1", "VIP-1", "Семейная")
  final String name; // Название комнаты
  final int capacity; // Вместимость (количество человек)
  final String status; // free, occupied, reserved, unavailable
  final double pricePerHour; // Цена за час (если есть)
  final String? description;
  final List<String> amenities; // Удобства: wifi, tv, кондиционер и т.д.
  final List<String> photos;
  final String? currentBookingId; // ID текущего бронирования
  final DateTime? lastUpdated;

  RoomModel({
    required this.id,
    required this.choyxonaId,
    required this.number,
    this.name = '',
    required this.capacity,
    required this.status,
    this.pricePerHour = 0,
    this.description,
    this.amenities = const [],
    this.photos = const [],
    this.currentBookingId,
    this.lastUpdated,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      choyxonaId: data['choyxonaId'] ?? '',
      number: data['number'] ?? '',
      name: data['name'] ?? '',
      capacity: data['capacity'] ?? 4,
      status: data['status'] ?? 'free',
      pricePerHour: (data['pricePerHour'] ?? 0).toDouble(),
      description: data['description'],
      amenities: List<String>.from(data['amenities'] ?? []),
      photos: List<String>.from(data['photos'] ?? []),
      currentBookingId: data['currentBookingId'],
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choyxonaId': choyxonaId,
      'number': number,
      'name': name,
      'capacity': capacity,
      'status': status,
      'pricePerHour': pricePerHour,
      'description': description,
      'amenities': amenities,
      'photos': photos,
      'currentBookingId': currentBookingId,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Проверка доступности
  bool get isFree => status == 'free';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
  bool get isUnavailable => status == 'unavailable';
  bool get isAvailable => isFree;

  /// Отображаемое название (номер или имя)
  String get displayName => name.isNotEmpty ? name : 'Xona $number';

  RoomModel copyWith({
    String? id,
    String? choyxonaId,
    String? number,
    String? name,
    int? capacity,
    String? status,
    double? pricePerHour,
    String? description,
    List<String>? amenities,
    List<String>? photos,
    String? currentBookingId,
    DateTime? lastUpdated,
  }) {
    return RoomModel(
      id: id ?? this.id,
      choyxonaId: choyxonaId ?? this.choyxonaId,
      number: number ?? this.number,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      photos: photos ?? this.photos,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
