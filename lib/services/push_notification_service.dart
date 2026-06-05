import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Сервис Push уведомлений через Firebase Cloud Messaging
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _token;
  String? get token => _token;

  /// Инициализация сервиса
  Future<void> initialize() async {
    // Запрос разрешений
    await _requestPermissions();
    
    // Получение токена
    await _getToken();
    
    // Настройка локальных уведомлений (только для мобильных платформ)
    if (!kIsWeb) {
      await _setupLocalNotifications();
    }
    
    // Слушатели сообщений
    _setupMessageHandlers();
  }

  /// Запрос разрешений на уведомления
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('Push notification permission: ${settings.authorizationStatus}');
  }

  /// Получение FCM токена
  Future<void> _getToken() async {
    try {
      // Для web нужен VAPID key
      if (kIsWeb) {
        _token = await _messaging.getToken(
          vapidKey: 'BKP3dp9o4QGNxwrziHH0qGQDYx4xlwMV2m76EVrNTP3bPFS8TWH-6eFA0nTEK-KOJ3UeI7tbIUPTeriU_U5k5R8',
        );
      } else {
        _token = await _messaging.getToken();
      }
      print('FCM Token (${kIsWeb ? "web" : "mobile"}): $_token');
      
      // Слушаем обновления токена
      _messaging.onTokenRefresh.listen((newToken) {
        _token = newToken;
        print('FCM Token refreshed: $newToken');
      });
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  /// Настройка локальных уведомлений
  Future<void> _setupLocalNotifications() async {
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
    
    // Создание канала уведомлений для Android (только для мобильного)
    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Настройка обработчиков сообщений
  void _setupMessageHandlers() {
    // Сообщение когда приложение на переднем плане
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Сообщение когда приложение открыто из уведомления
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Обработка сообщения на переднем плане
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.notification?.title}');
    
    final notification = message.notification;
    // На web не показываем локальные уведомления - браузер сам покажет
    if (notification != null && !kIsWeb) {
      await _showLocalNotification(
        title: notification.title ?? 'Choyxona UZ',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Обработка открытия из уведомления
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.notification?.title}');
    // Здесь можно навигировать на соответствующий экран
  }

  /// Показать локальное уведомление
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Обработка нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  /// Сохранить токен пользователя в Firestore
  Future<void> saveTokenToFirestore(String userId) async {
    if (_token == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'deviceTokens': FieldValue.arrayUnion([_token]),
      });
      print('Token saved for user: $userId');
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  /// Удалить токен при выходе
  Future<void> removeTokenFromFirestore(String userId) async {
    if (_token == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'deviceTokens': FieldValue.arrayRemove([_token]),
      });
      print('Token removed for user: $userId');
    } catch (e) {
      print('Error removing token: $e');
    }
  }

  /// Отправить уведомление (через Cloud Functions или напрямую)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Создаём запись в коллекции notifications
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('Notification created for user: $userId');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Подписаться на тему
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  /// Отписаться от темы
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}
