import 'package:cloud_firestore/cloud_firestore.dart';

/// Элемент заказа (блюдо)
class OrderItem {
  final String dishId;
  final String dishName;
  final double price;
  final double quantity; // Changed to double for kg support
  final String unit; // 'dona', 'kg', 'litr', 'porshon'
  final String? notes;
  final String? deliveryTime; // Время доставки блюда, например "21:40"

  OrderItem({
    required this.dishId,
    required this.dishName,
    required this.price,
    required this.quantity,
    this.unit = 'dona',
    this.notes,
    this.deliveryTime,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      dishId: data['dishId'] ?? '',
      dishName: data['dishName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 1).toDouble(),
      unit: data['unit'] ?? 'dona',
      notes: data['notes'],
      deliveryTime: data['deliveryTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dishId': dishId,
      'dishName': dishName,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
      'deliveryTime': deliveryTime,
    };
  }

  double get total => price * quantity;

  /// Формат для отображения (например: "2 kg" или "3 dona")
  String get quantityDisplay => '$quantity $unit';
}

/// Модель заказа
class OrderModel {
  final String id;
  final String choyxonaId;
  final String? bookingId; // Связь с бронированием
  final String? tableId;
  final String? tableNumber;
  final String userId; // Кто клиент
  final List<OrderItem> items;
  final String status; // new, preparing, ready, served, paid, cancelled
  final double subtotal;
  final double discount;
  final double tips;
  final double total;
  final String addedBy; // 'client' или 'admin' - кто добавил заказ
  final String? adminNote; // Примечание от администратора
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;
  final bool isRated; // Оценен ли заказ

  OrderModel({
    required this.id,
    required this.choyxonaId,
    this.bookingId,
    this.tableId,
    this.tableNumber,
    required this.userId,
    required this.items,
    required this.status,
    required this.subtotal,
    this.discount = 0,
    this.tips = 0,
    required this.total,
    this.addedBy = 'client',
    this.adminNote,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
    this.isRated = false,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = data['items'] as List<dynamic>? ?? [];

    return OrderModel(
      id: doc.id,
      choyxonaId: data['choyxonaId'] ?? '',
      bookingId: data['bookingId'],
      tableId: data['tableId'],
      tableNumber: data['tableNumber'],
      userId: data['userId'] ?? '',
      items: itemsList
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      status: data['status'] ?? 'new',
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      tips: (data['tips'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      addedBy: data['addedBy'] ?? 'client',
      adminNote: data['adminNote'],
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      isRated: data['isRated'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choyxonaId': choyxonaId,
      'bookingId': bookingId,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status,
      'subtotal': subtotal,
      'discount': discount,
      'tips': tips,
      'total': total,
      'addedBy': addedBy,
      'adminNote': adminNote,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
      'paidAt': paidAt,
      'isRated': isRated,
    };
  }

  static double calculateTotal(double subtotal, double discount, double tips) {
    final discountAmount = subtotal * (discount / 100);
    return subtotal - discountAmount + tips;
  }

  // Статусы
  bool get isNew => status == 'new';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isServed => status == 'served';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';

  // Compatibility getters
  String get orderId => id;
  double get totalAmount => total;

  /// Добавить новый элемент в заказ
  OrderModel addItem(OrderItem newItem) {
    final newItems = List<OrderItem>.from(items)..add(newItem);
    final newSubtotal = newItems.fold<double>(0, (sum, item) => sum + item.total);
    final newTotal = calculateTotal(newSubtotal, discount, tips);
    
    return copyWith(
      items: newItems,
      subtotal: newSubtotal,
      total: newTotal,
    );
  }

  OrderModel copyWith({
    String? id,
    String? choyxonaId,
    String? bookingId,
    String? tableId,
    String? tableNumber,
    String? userId,
    List<OrderItem>? items,
    String? status,
    double? subtotal,
    double? discount,
    double? tips,
    double? total,
    String? addedBy,
    String? adminNote,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    bool? isRated,
  }) {
    return OrderModel(
      id: id ?? this.id,
      choyxonaId: choyxonaId ?? this.choyxonaId,
      bookingId: bookingId ?? this.bookingId,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tips: tips ?? this.tips,
      total: total ?? this.total,
      addedBy: addedBy ?? this.addedBy,
      adminNote: adminNote ?? this.adminNote,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      isRated: isRated ?? this.isRated,
    );
  }
}
