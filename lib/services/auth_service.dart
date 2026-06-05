import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../core/utils/error_handler.dart';
import 'push_notification_service.dart';

/// Сервис авторизации с поддержкой ролей
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Текущий пользователь
  User? get currentUser => _auth.currentUser;

  /// Stream текущего пользователя
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Регистрация с email и паролем
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    String role = 'client', // По умолчанию клиент
  }) async {
    try {
      // Создаём пользователя в Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {
          'success': false,
          'message': 'Ошибка создания пользователя',
        };
      }

      // Создаём документ пользователя в Firestore
      final userModel = UserModel(
        userId: user.uid,
        email: email,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
        photoUrl: '',
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        favoriteChoyxonas: [],
        totalBookings: 0,
        deviceTokens: [],
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      // Пропускаем верификацию email для автогенерированных адресов (регистрация по телефону)
      if (!email.endsWith('@choyxona.local')) {
        await user.sendEmailVerification();
      }

      return {
        'success': true,
        'message': 'Регистрация успешна! Теперь вы можете войти.',
        'user': userModel,
      };
    } catch (e, stackTrace) {
      return {
        'success': false,
        'message': ErrorHandler.getUserMessage(e, stackTrace: stackTrace),
      };
    }
  }

  /// Вход с email и паролем
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {
          'success': false,
          'message': 'Ошибка входа',
        };
      }

      // Получаем данные пользователя из Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'Данные пользователя не найдены',
        };
      }

      final userModel = UserModel.fromFirestore(userDoc);

      // Проверяем активен ли аккаунт
      if (!userModel.isActive) {
        await signOut();
        return {
          'success': false,
          'message': 'Ваш аккаунт заблокирован. Обратитесь в поддержку.',
        };
      }

      // FCM token saqlash push notification uchun
      try {
        await PushNotificationService().saveTokenToFirestore(user.uid);
      } catch (e) {
        // Token saqlashda xatolik push ga ta'sir qilmasin
        print('Error saving FCM token: $e');
      }

      return {
        'success': true,
        'message': 'Вход выполнен успешно!',
        'user': userModel,
      };
    } catch (e, stackTrace) {
      return {
        'success': false,
        'message': ErrorHandler.getUserMessage(e, stackTrace: stackTrace),
      };
    }
  }

  /// Выход
  Future<void> signOut() async {
    // FCM tokenni o'chirish - bu juda muhim!
    final userId = currentUser?.uid;
    if (userId != null) {
      try {
        await PushNotificationService().removeTokenFromFirestore(userId);
        debugPrint('✅ FCM token removed for user: $userId');
      } catch (e) {
        debugPrint('⚠️ Error removing FCM token: $e');
      }
    }
    await _auth.signOut();
  }

  /// Получить данные текущего пользователя
  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      return null;
    }
  }

  /// Сброс пароля
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Письмо для сброса пароля отправлено на $email',
      };
    } catch (e, stackTrace) {
      return {
        'success': false,
        'message': ErrorHandler.getUserMessage(e, stackTrace: stackTrace),
      };
    }
  }

  /// Обновить профиль пользователя
  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(user.uid).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Изменить роль пользователя (только для admin)
  Future<bool> changeUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Проверить роль пользователя
  Future<String?> getUserRole() async {
    try {
      final userData = await getCurrentUserData();
      return userData?.role;
    } catch (e) {
      return null;
    }
  }
}
