import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель стола
class TableModel {
  final String id;
  final String choyxonaId;
  final String number; // Номер стола (например: "1", "A1", "VIP-1")
  final int capacity; // Вместимость (количество мест)
  final String status; // free, occupied, reserved, unavailable
  final String? currentOrderId; // ID текущего заказа
  final String? currentBookingId; // ID текущего бронирования
  final double positionX; // Позиция на карте зала (X координата)
  final double positionY; // Позиция на карте зала (Y координата)
  final String shape; // circle, square, rectangle
  final DateTime? lastUpdated;

  TableModel({
    required this.id,
    required this.choyxonaId,
    required this.number,
    required this.capacity,
    required this.status,
    this.currentOrderId,
    this.currentBookingId,
    required this.positionX,
    required this.positionY,
    this.shape = 'circle',
    this.lastUpdated,
  });

  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableModel(
      id: doc.id,
      choyxonaId: data['choyxonaId'] ?? '',
      number: data['number'] ?? '',
      capacity: data['capacity'] ?? 4,
      status: data['status'] ?? 'free',
      currentOrderId: data['currentOrderId'],
      currentBookingId: data['currentBookingId'],
      positionX: (data['positionX'] ?? 0).toDouble(),
      positionY: (data['positionY'] ?? 0).toDouble(),
      shape: data['shape'] ?? 'circle',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choyxonaId': choyxonaId,
      'number': number,
      'capacity': capacity,
      'status': status,
      'currentOrderId': currentOrderId,
      'currentBookingId': currentBookingId,
      'positionX': positionX,
      'positionY': positionY,
      'shape': shape,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Проверка доступности стола
  bool get isAvailable => status == 'free';
  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
  bool get isUnavailable => status == 'unavailable';

  // Копирование с изменениями
  TableModel copyWith({
    String? id,
    String? choyxonaId,
    String? number,
    int? capacity,
    String? status,
    String? currentOrderId,
    String? currentBookingId,
    double? positionX,
    double? positionY,
    String? shape,
    DateTime? lastUpdated,
  }) {
    return TableModel(
      id: id ?? this.id,
      choyxonaId: choyxonaId ?? this.choyxonaId,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      shape: shape ?? this.shape,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}