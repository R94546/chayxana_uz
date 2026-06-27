import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../core/utils/error_handler.dart';

/// Сервис для работы с бронированиями
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Идентификатор замка комнаты на день (одна комната = один день = одно бронирование)
  String _roomLockId(String roomId, String bookingDate) => '${roomId}_$bookingDate';

  /// Создать новое бронирование (атомарно, с проверкой занятости комнаты по дню)
  ///
  /// Логика вместимости: вместимость чайханы = количество комнат.
  /// Комната занята на день, если для неё уже есть активная (pending/confirmed)
  /// бронь на эту дату. Атомарность обеспечивается детерминированным документом
  /// замка `room_locks/{roomId}_{bookingDate}` (в транзакции нельзя делать запросы).
  Future<String?> createBooking(BookingModel booking) async {
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

    final hasRoom = booking.roomId != null && booking.roomId!.isNotEmpty;

    try {
      return await _firestore.runTransaction<String?>((tx) async {
        // Проверка занятости комнаты (если комната выбрана)
        if (hasRoom) {
          final lockRef = _firestore
              .collection('room_locks')
              .doc(_roomLockId(booking.roomId!, booking.bookingDate));
          final lockSnap = await tx.get(lockRef);
          if (lockSnap.exists) {
            return 'Bu xona tanlangan kunga allaqachon band. Iltimos, boshqa xona yoki sana tanlang.';
          }
          // Ставим замок
          tx.set(lockRef, {
            'roomId': booking.roomId,
            'choyxonaId': booking.choyxonaId,
            'bookingDate': booking.bookingDate,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Создаём бронь
        final bookingRef = _firestore.collection('bookings').doc();
        tx.set(bookingRef, booking.toMap());

        // Счётчики (totalBookings / bookingCount) инкрементирует Cloud Function
        // onBookingCreated через admin SDK — клиент не имеет прав на choyxonas.update,
        // иначе вся транзакция была бы отклонена правилами.

        return null; // Успех
      });
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Получить занятые комнаты (id) на конкретную дату для чайханы
  Future<Set<String>> getOccupiedRoomIds(String choyxonaId, String bookingDate) async {
    try {
      final snapshot = await _firestore
          .collection('room_locks')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .where('bookingDate', isEqualTo: bookingDate)
          .get();
      return snapshot.docs
          .map((d) => (d.data()['roomId'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return {};
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

  /// Подтвердить бронь, у которой комната уже выбрана пользователем
  /// (замок room_locks уже стоит — просто меняем статус на confirmed).
  Future<String?> confirmBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
    }
  }

  /// Подтвердить бронь и атомарно назначить комнату (для брони без комнаты —
  /// «пусть выберет админ»). Ставит замок room_locks на день, чтобы вместимость
  /// не нарушалась, и обновляет бронь (roomId/roomNumber + status=confirmed).
  Future<String?> assignRoomAndConfirm({
    required String bookingId,
    required String roomId,
    required String roomNumber,
    required String choyxonaId,
    required String bookingDate,
  }) async {
    try {
      return await _firestore.runTransaction<String?>((tx) async {
        final lockRef = _firestore
            .collection('room_locks')
            .doc(_roomLockId(roomId, bookingDate));
        final lockSnap = await tx.get(lockRef);
        if (lockSnap.exists) {
          return 'Bu xona tanlangan kunga allaqachon band. Boshqa xona tanlang.';
        }
        tx.set(lockRef, {
          'roomId': roomId,
          'choyxonaId': choyxonaId,
          'bookingDate': bookingDate,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(_firestore.collection('bookings').doc(bookingId), {
          'roomId': roomId,
          'roomNumber': roomNumber,
          'status': 'confirmed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return null;
      });
    } catch (e, stackTrace) {
      return ErrorHandler.getUserMessage(e, stackTrace: stackTrace);
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

      // Замок комнаты (room_locks) освобождается Cloud Function onBookingStatusChanged
      // при переходе брони в статус cancelled — клиенту не нужны права на удаление.

      // Если был назначен стол, освобождаем его (устаревшее)
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

  /// Проверить, есть ли свободные комнаты в чайхане на дату (вместимость = кол-во комнат)
  Future<bool> hasAvailabilityOnDate({
    required String choyxonaId,
    required String bookingDate,
  }) async {
    try {
      final roomsSnap = await _firestore
          .collection('rooms')
          .where('choyxonaId', isEqualTo: choyxonaId)
          .get();
      final totalRooms = roomsSnap.docs
          .where((d) => (d.data()['status'] ?? 'free') != 'unavailable')
          .length;
      if (totalRooms == 0) return false;

      final occupied = await getOccupiedRoomIds(choyxonaId, bookingDate);
      return occupied.length < totalRooms;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return false;
    }
  }

  /// Проверить, свободна ли конкретная комната на дату
  Future<bool> isRoomAvailable({
    required String roomId,
    required String bookingDate,
  }) async {
    try {
      final lock = await _firestore
          .collection('room_locks')
          .doc(_roomLockId(roomId, bookingDate))
          .get();
      return !lock.exists;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return false;
    }
  }
}

