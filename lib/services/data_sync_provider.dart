import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/choyxona_model.dart';

/// Глобальный провайдер для синхронизации данных между экранами
/// Использует Firestore real-time listeners для автоматического обновления
class DataSyncProvider extends ChangeNotifier {
  static final DataSyncProvider _instance = DataSyncProvider._internal();
  factory DataSyncProvider() => _instance;
  DataSyncProvider._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Подписки на streams
  StreamSubscription<QuerySnapshot>? _choyxonasSubscription;
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  StreamSubscription<QuerySnapshot>? _reviewsSubscription;
  StreamSubscription<QuerySnapshot>? _usersSubscription;

  // Кеш данных
  List<Choyxona> _choyxonas = [];
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _users = [];

  // Статусы загрузки
  bool _isChoyxonasLoading = true;
  bool _isBookingsLoading = true;
  bool _isReviewsLoading = true;
  bool _isUsersLoading = true;

  // Getters
  List<Choyxona> get choyxonas => _choyxonas;
  List<Map<String, dynamic>> get bookings => _bookings;
  List<Map<String, dynamic>> get reviews => _reviews;
  List<Map<String, dynamic>> get users => _users;

  bool get isChoyxonasLoading => _isChoyxonasLoading;
  bool get isBookingsLoading => _isBookingsLoading;
  bool get isReviewsLoading => _isReviewsLoading;
  bool get isUsersLoading => _isUsersLoading;

  // Статистика
  int get totalChoyxonas => _choyxonas.length;
  int get totalBookings => _bookings.length;
  int get totalReviews => _reviews.length;
  int get totalUsers => _users.length;
  
  int get pendingBookings => _bookings.where((b) => b['status'] == 'pending').length;
  int get confirmedBookings => _bookings.where((b) => b['status'] == 'confirmed').length;
  int get todayBookings {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _bookings.where((b) => b['bookingDate'] == todayStr).length;
  }

  /// Инициализация всех подписок
  /// ПРИМЕЧАНИЕ: bookings и users отключены - требуют права админа
  void initialize() {
    _listenToChoyxonas();
    // _listenToBookings(); // Отключено - требует админ прав
    _listenToReviews();
    // _listenToUsers(); // Отключено - требует админ прав
    
    // Mark as loaded since we're not fetching
    _isBookingsLoading = false;
    _isUsersLoading = false;
  }

  /// Подписка на чайханы
  void _listenToChoyxonas() {
    _choyxonasSubscription?.cancel();
    _choyxonasSubscription = _firestore
        .collection('choyxonas')
        .snapshots()
        .listen((snapshot) {
      _choyxonas = snapshot.docs.map((doc) => Choyxona.fromFirestore(doc)).toList();
      _isChoyxonasLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to choyxonas: $e');
      _isChoyxonasLoading = false;
      notifyListeners();
    });
  }

  /// Подписка на брони
  void _listenToBookings() {
    _bookingsSubscription?.cancel();
    _bookingsSubscription = _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _isBookingsLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to bookings: $e');
      _isBookingsLoading = false;
      notifyListeners();
    });
  }

  /// Подписка на отзывы
  void _listenToReviews() {
    _reviewsSubscription?.cancel();
    _reviewsSubscription = _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _reviews = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _isReviewsLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to reviews: $e');
      _isReviewsLoading = false;
      notifyListeners();
    });
  }

  /// Подписка на пользователей
  void _listenToUsers() {
    _usersSubscription?.cancel();
    _usersSubscription = _firestore
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      _users = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _isUsersLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to users: $e');
      _isUsersLoading = false;
      notifyListeners();
    });
  }

  /// Получить чайхану по ID
  Choyxona? getChoyxonaById(String id) {
    try {
      return _choyxonas.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Получить брони для чайханы
  List<Map<String, dynamic>> getBookingsForChoyxona(String choyxonaId) {
    return _bookings.where((b) => b['choyxonaId'] == choyxonaId).toList();
  }

  /// Получить брони для даты
  List<Map<String, dynamic>> getBookingsForDate(String choyxonaId, String date) {
    return _bookings.where((b) => 
      b['choyxonaId'] == choyxonaId && 
      b['bookingDate'] == date &&
      (b['status'] == 'pending' || b['status'] == 'confirmed')
    ).toList();
  }

  /// Получить количество занятых слотов для времени
  int getBookedSlotsCount(String choyxonaId, String date, String timeSlot) {
    return _bookings.where((b) =>
      b['choyxonaId'] == choyxonaId &&
      b['bookingDate'] == date &&
      b['bookingTime'] == timeSlot &&
      (b['status'] == 'pending' || b['status'] == 'confirmed')
    ).length;
  }

  /// Получить отзывы для чайханы
  List<Map<String, dynamic>> getReviewsForChoyxona(String choyxonaId) {
    return _reviews.where((r) => r['choyxonaId'] == choyxonaId).toList();
  }

  /// Получить средний рейтинг чайханы
  double getAverageRating(String choyxonaId) {
    final choyxonaReviews = getReviewsForChoyxona(choyxonaId);
    if (choyxonaReviews.isEmpty) return 0.0;
    
    final totalRating = choyxonaReviews.fold<double>(
      0.0, 
      (total, r) => total + (r['rating'] as num? ?? 0).toDouble()
    );
    return totalRating / choyxonaReviews.length;
  }

  /// Получить пользователя по ID
  Map<String, dynamic>? getUserById(String userId) {
    try {
      return _users.firstWhere((u) => u['id'] == userId);
    } catch (_) {
      return null;
    }
  }

  /// Освобождение ресурсов
  @override
  void dispose() {
    _choyxonasSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _reviewsSubscription?.cancel();
    _usersSubscription?.cancel();
    super.dispose();
  }
}
