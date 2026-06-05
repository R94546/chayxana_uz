import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Централизованный обработчик ошибок
class ErrorHandler {
  /// Обработать ошибку Firebase Auth
  static String handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'Пользователь с таким email не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'weak-password':
        return 'Пароль слишком слабый. Минимум 6 символов';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'user-disabled':
        return 'Этот аккаунт заблокирован';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'network-request-failed':
        return 'Ошибка сети. Проверьте подключение к интернету';
      case 'invalid-credential':
        return 'Неверные учётные данные';
      case 'account-exists-with-different-credential':
        return 'Аккаунт с таким email уже существует';
      case 'requires-recent-login':
        return 'Требуется повторный вход в систему';
      default:
        return 'Ошибка авторизации: ${error.message ?? error.code}';
    }
  }

  /// Обработать ошибку Firestore
  static String handleFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Недостаточно прав для выполнения операции';
      case 'not-found':
        return 'Документ не найден';
      case 'already-exists':
        return 'Документ уже существует';
      case 'resource-exhausted':
        return 'Превышен лимит запросов. Попробуйте позже';
      case 'failed-precondition':
        return 'Операция не может быть выполнена';
      case 'aborted':
        return 'Операция прервана. Попробуйте снова';
      case 'out-of-range':
        return 'Недопустимое значение';
      case 'unimplemented':
        return 'Операция не поддерживается';
      case 'internal':
        return 'Внутренняя ошибка сервера';
      case 'unavailable':
        return 'Сервис временно недоступен';
      case 'data-loss':
        return 'Потеря данных';
      case 'unauthenticated':
        return 'Требуется авторизация';
      case 'deadline-exceeded':
        return 'Превышено время ожидания';
      case 'cancelled':
        return 'Операция отменена';
      default:
        return 'Ошибка базы данных: ${error.message ?? error.code}';
    }
  }

  /// Обработать ошибку Firebase Storage
  static String handleStorageError(FirebaseException error) {
    switch (error.code) {
      case 'object-not-found':
        return 'Файл не найден';
      case 'bucket-not-found':
        return 'Хранилище не найдено';
      case 'project-not-found':
        return 'Проект не найден';
      case 'quota-exceeded':
        return 'Превышена квота хранилища';
      case 'unauthenticated':
        return 'Требуется авторизация';
      case 'unauthorized':
        return 'Недостаточно прав для доступа к файлу';
      case 'retry-limit-exceeded':
        return 'Превышен лимит попыток загрузки';
      case 'invalid-checksum':
        return 'Файл повреждён';
      case 'canceled':
        return 'Загрузка отменена';
      case 'invalid-event-name':
        return 'Неверное событие';
      case 'invalid-url':
        return 'Неверный URL';
      case 'invalid-argument':
        return 'Неверный аргумент';
      case 'no-default-bucket':
        return 'Хранилище не настроено';
      case 'cannot-slice-blob':
        return 'Ошибка обработки файла';
      case 'server-file-wrong-size':
        return 'Размер файла не совпадает';
      default:
        return 'Ошибка загрузки: ${error.message ?? error.code}';
    }
  }

  /// Обработать сетевую ошибку
  static String handleNetworkError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('socket') ||
        errorMessage.contains('network') ||
        errorMessage.contains('connection')) {
      return 'Ошибка сети. Проверьте подключение к интернету';
    }

    if (errorMessage.contains('timeout')) {
      return 'Превышено время ожидания. Попробуйте снова';
    }

    if (errorMessage.contains('host')) {
      return 'Не удалось подключиться к серверу';
    }

    return 'Произошла ошибка. Попробуйте позже';
  }

  /// Универсальный обработчик ошибок
  static String handleError(dynamic error) {
    if (error is FirebaseAuthException) {
      return handleAuthError(error);
    } else if (error is FirebaseException) {
      // Проверяем, это Firestore или Storage
      if (error.plugin == 'cloud_firestore') {
        return handleFirestoreError(error);
      } else if (error.plugin == 'firebase_storage') {
        return handleStorageError(error);
      } else {
        return 'Ошибка Firebase: ${error.message ?? error.code}';
      }
    } else {
      return handleNetworkError(error);
    }
  }

  /// Логирование ошибки (для разработки)
  static void logError(dynamic error, StackTrace? stackTrace) {
    print('═══════════════════════════════════════');
    print('❌ ERROR: ${error.toString()}');
    if (stackTrace != null) {
      print('📍 STACK TRACE:');
      print(stackTrace.toString());
    }
    print('═══════════════════════════════════════');
  }

  /// Показать ошибку пользователю (возвращает user-friendly сообщение)
  static String getUserMessage(dynamic error, {StackTrace? stackTrace}) {
    // Логируем для разработки
    logError(error, stackTrace);

    // Возвращаем понятное сообщение
    return handleError(error);
  }
}
