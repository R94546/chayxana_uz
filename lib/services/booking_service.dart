import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../core/utils/error_handler.dart';

/// Сервис для работы с бронированиями
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать новое бронирование
  Future<String?> createBooking(BookingModel booking) async {
    try {
      // Валидация
      final validationError = BookingModel.validateBooking(
        bookingDate: booking.bookingDate,
        bookingTime: booking.bookingTime,
        guestCount: booking.guestCount,
        guestName: booking.guestName,
        guestPhone: booking.guestPhone,
      );

      if (validationError != null) {
        return validationError;
      }

      // Создаём документ
      await _firestore.collection('bookings').add(booking.toMap());

      // Обновляем счётчик бронирований у пользователя
      await _firestore.collection('users').doc(booking.userId).update({
        'totalBookings': FieldValue.increment(1),
      });

      // Обновляем счётчик бронирований у чайханы
      await _firestore.collection('choyxonas').doc(booking.choyxonaId).update({
        'bookingCount': FieldValue.increment(1),
      });

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Получить все бронирования пользователя
  Future<List<BookingModel>> getBookingsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить активные бронирования пользователя
  Future<List<BookingModel>> getActiveBookingsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('bookingDate')
          .get();

      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить бронирования чайханы
  Future<List<BookingModel>> getBookingsByChoyxona(String choyxonaId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .orderBy('bookingDate', descending: true)
          .get();

      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Получить ожидающие подтверждения бронирования
  Future<List<BookingModel>> getPendingBookings(String choyxonaId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return [];
    }
  }

  /// Обновить статус бронирования
  Future<String?> updateBookingStatus({
    required String bookingId,
    required String status,
    String? tableNumber,
    String? tableId,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (tableNumber != null) {
        updateData['tableNumber'] = tableNumber;
      }

      if (tableId != null) {
        updateData['tableId'] = tableId;
      }

      await _firestore.collection('bookings').doc(bookingId).update(updateData);

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Отменить бронирование
  Future<String?> cancelBooking({
    required String bookingId,
    String? cancellationReason,
  }) async {
    try {
      // Получаем бронирование
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (!doc.exists) {
        return 'Бронирование не найдено';
      }

      final booking = BookingModel.fromFirestore(doc);

      // Проверяем, можно ли отменить
      if (!booking.canCancel()) {
        return 'Нельзя отменить бронирование менее чем за 2 часа';
      }

      // Обновляем статус
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancellationReason': cancellationReason ?? 'Отменено пользователем',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Если был назначен стол, освобождаем его
      if (booking.tableId != null) {
        await _firestore.collection('tables').doc(booking.tableId).update({
          'status': 'free',
          'currentBookingId': null,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Завершить бронирование
  Future<String?> completeBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return null; // Успех
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Получить бронирование по ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (!doc.exists) {
        return null;
      }

      return BookingModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return null;
    }
  }

  /// Stream бронирований пользователя (real-time)
  Stream<List<BookingModel>> streamUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  /// Stream ожидающих бронирований (real-time)
  Stream<List<BookingModel>> streamPendingBookings(String choyxonaId) {
    return _firestore
        .collection('bookings')
        .where('choyxonaId', isEqualTo: choyxonaId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  /// Проверить доступность на дату и время
  Future<bool> checkAvailability({
    required String choyxonaId,
    required String bookingDate,
    required String bookingTime,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .where('bookingDate', isEqualTo: bookingDate)
          .where('bookingTime', isEqualTo: bookingTime)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      // Если есть бронирования на это время, проверяем количество
      // TODO: Добавить проверку вместимости чайханы
      return snapshot.docs.length < 10; // Временное ограничение
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return false;
    }
  }
}

