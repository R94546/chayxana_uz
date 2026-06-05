import 'package:cloud_firestore/cloud_firestore.dart';

/// Роли пользователей в системе
class UserRole {
  static const String client = 'client';
  static const String superAdmin = 'superadmin';
  static const String choyxonaAdmin = 'choyxona_admin';
  static const String choyxonaOwner = 'choyxona_owner';
}

/// Модель пользователя
class UserModel {
  final String userId;
  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String photoUrl;
  final String role; // 'client', 'superadmin', 'choyxona_admin', 'choyxona_owner'
  final String? choyxonaId; // ID чайханы (для админов чайхан)
  final String? assignedBy; // Кто назначил роль (для админов)
  final DateTime? assignedAt; // Когда назначена роль
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final List<String> favoriteChoyxonas;
  final int totalBookings;
  final List<String> deviceTokens;

  UserModel({
    required this.userId,
    required this.email,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.photoUrl,
    required this.role,
    this.choyxonaId,
    this.assignedBy,
    this.assignedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.favoriteChoyxonas,
    required this.totalBookings,
    required this.deviceTokens,
  });

  /// Полное имя пользователя
  String get fullName => '$firstName $lastName';

  /// Инициалы
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  /// Проверка ролей
  bool get isClient => role == UserRole.client;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isChoyxonaAdmin => role == UserRole.choyxonaAdmin;
  bool get isChoyxonaOwner => role == UserRole.choyxonaOwner;
  
  /// Может управлять чайханой (admin или owner)
  bool get canManageChoyxona => isChoyxonaAdmin || isChoyxonaOwner;
  
  /// Только просмотр (choyxona_owner)
  bool get isViewOnly => isChoyxonaOwner;

  /// Создать из Firestore документа
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      role: data['role'] ?? UserRole.client,
      choyxonaId: data['choyxonaId'],
      assignedBy: data['assignedBy'],
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      favoriteChoyxonas: List<String>.from(data['favoriteChoyxonas'] ?? []),
      totalBookings: data['totalBookings'] ?? 0,
      deviceTokens: List<String>.from(data['deviceTokens'] ?? []),
    );
  }

  /// Конвертировать в Map для Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'role': role,
      'choyxonaId': choyxonaId,
      'assignedBy': assignedBy,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'favoriteChoyxonas': favoriteChoyxonas,
      'totalBookings': totalBookings,
      'deviceTokens': deviceTokens,
    };
  }

  /// Копировать с изменениями
  UserModel copyWith({
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? role,
    String? choyxonaId,
    String? assignedBy,
    DateTime? assignedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<String>? favoriteChoyxonas,
    int? totalBookings,
    List<String>? deviceTokens,
  }) {
    return UserModel(
      userId: userId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      choyxonaId: choyxonaId ?? this.choyxonaId,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      favoriteChoyxonas: favoriteChoyxonas ?? this.favoriteChoyxonas,
      totalBookings: totalBookings ?? this.totalBookings,
      deviceTokens: deviceTokens ?? this.deviceTokens,
    );
  }

  /// Получить название роли для отображения
  String getRoleDisplayName() {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.choyxonaAdmin:
        return 'Администратор чайханы';
      case UserRole.choyxonaOwner:
        return 'Владелец чайханы';
      case UserRole.client:
      default:
        return 'Клиент';
    }
  }
}