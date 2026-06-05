import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/data_sync_provider.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Настройка background handler для FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await initializeDateFormatting('ru', null);

  // Инициализация easy_localization
  await EasyLocalization.ensureInitialized();

  // Инициализация push-уведомлений
  await NotificationService().initialize();
  
  // Инициализация FCM Push уведомлений (запрос разрешений)
  await PushNotificationService().initialize();
  
  // ONE-TIME FIX: Remove extra quotes from admin choyxonaId
  await _fixAdminChoyxonaId();

  // Инициализация глобального провайдера синхронизации данных
  final dataSyncProvider = DataSyncProvider();
  dataSyncProvider.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ru'), Locale('uz'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      child: MyApp(dataSyncProvider: dataSyncProvider),
    ),
  );
}

class MyApp extends StatelessWidget {
  final DataSyncProvider dataSyncProvider;
  
  const MyApp({super.key, required this.dataSyncProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: dataSyncProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Choyxona UZ',
            debugShowCheckedModeBanner: false,

            // Локализация
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,

            // Темы
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Начальный экран
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// ONE-TIME FIX: Remove extra quotes from admin choyxonaId
Future<void> _fixAdminChoyxonaId() async {
  try {
    final adminQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: 'admin@gmail.com')
        .get();
    
    if (adminQuery.docs.isEmpty) return;
    
    final adminDoc = adminQuery.docs.first;
    final data = adminDoc.data();
    final currentChoyxonaId = data['choyxonaId'] as String?;
    
    if (currentChoyxonaId == null) return;
    
    // Remove extra quotes if present
    if (currentChoyxonaId.startsWith('"') && currentChoyxonaId.endsWith('"')) {
      final fixedId = currentChoyxonaId.substring(1, currentChoyxonaId.length - 1);
      await adminDoc.reference.update({'choyxonaId': fixedId});
      print('✅ Fixed admin choyxonaId: $fixedId');
    }
  } catch (e) {
    print('Error fixing choyxonaId: $e');
  }
}
