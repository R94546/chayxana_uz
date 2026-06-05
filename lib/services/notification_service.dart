import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🔔 Notification Service - Push уведомления
/// Использует Firebase Cloud Messaging + Flutter Local Notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    // Запрос разрешений
    await _requestPermissions();
    
    // Инициализация локальных уведомлений
    await _initLocalNotifications();
    
    // Получение FCM токена
    await _getFcmToken();
    
    // Обработка сообщений
    _setupMessageHandlers();
    
    debugPrint('🔔 NotificationService initialized');
  }

  /// Запрос разрешений на уведомления
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
  }

  /// Инициализация локальных уведомлений
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Создание канала для Android
    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'choyxona_channel',
        'Choyxona Notifications',
        description: 'Уведомления о бронированиях и акциях',
        importance: Importance.high,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Получение FCM токена
  Future<void> _getFcmToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('🔔 FCM Token: $_fcmToken');
      
      // Слушаем обновления токена
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔔 FCM Token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('🔔 Error getting FCM token: $e');
    }
  }

  /// Настройка обработчиков сообщений
  void _setupMessageHandlers() {
    // Foreground сообщения
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Background/Terminated сообщения при открытии
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Обработка сообщений в foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 Foreground message: ${message.notification?.title}');
    
    // Показываем локальное уведомление
    await showLocalNotification(
      title: message.notification?.title ?? 'Choyxona',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Обработка нажатия на уведомление
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('🔔 Message opened app: ${message.notification?.title}');
    // TODO: Навигация к соответствующему экрану
  }

  /// Callback при нажатии на локальное уведомление
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // TODO: Навигация на основе payload
  }

  /// Показать локальное уведомление
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'choyxona_channel',
      'Choyxona Notifications',
      channelDescription: 'Уведомления о бронированиях и акциях',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Сохранить FCM токен пользователя в Firestore
  Future<void> saveUserToken(String userId) async {
    if (_fcmToken == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🔔 FCM token saved for user: $userId');
    } catch (e) {
      debugPrint('🔔 Error saving FCM token: $e');
    }
  }

  /// Подписаться на топик
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('🔔 Subscribed to topic: $topic');
  }

  /// Отписаться от топика
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('🔔 Unsubscribed from topic: $topic');
  }

  // ========== Типизированные уведомления ==========

  /// Уведомление о подтверждении бронирования
  Future<void> notifyBookingConfirmed({
    required String choyxonaName,
    required String date,
    required String time,
  }) async {
    await showLocalNotification(
      title: '✅ Бронирование подтверждено',
      body: '$choyxonaName - $date в $time',
      payload: 'booking_confirmed',
    );
  }

  /// Уведомление об отмене бронирования
  Future<void> notifyBookingCancelled({
    required String choyxonaName,
    required String reason,
  }) async {
    await showLocalNotification(
      title: '❌ Бронирование отменено',
      body: '$choyxonaName: $reason',
      payload: 'booking_cancelled',
    );
  }

  /// Напоминание о бронировании (за 1 час)
  Future<void> notifyBookingReminder({
    required String choyxonaName,
    required String time,
  }) async {
    await showLocalNotification(
      title: '⏰ Напоминание',
      body: 'Ваше бронирование в $choyxonaName через 1 час ($time)',
      payload: 'booking_reminder',
    );
  }

  /// Уведомление о новой акции
  Future<void> notifyNewPromotion({
    required String choyxonaName,
    required String promotionTitle,
  }) async {
    await showLocalNotification(
      title: '🎉 Новая акция!',
      body: '$choyxonaName: $promotionTitle',
      payload: 'new_promotion',
    );
  }

  /// Уведомление о новом отзыве (для владельца)
  Future<void> notifyNewReview({
    required String choyxonaName,
    required int rating,
  }) async {
    await showLocalNotification(
      title: '⭐ Новый отзыв',
      body: '$choyxonaName получила оценку $rating звёзд',
      payload: 'new_review',
    );
  }
}

/// Background message handler (должен быть top-level функцией)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message: ${message.notification?.title}');
}
