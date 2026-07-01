import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  await initializeDateFormatting('uz', null);

  // Инициализация easy_localization
  await EasyLocalization.ensureInitialized();

  // Инициализация push-уведомлений
  await NotificationService().initialize();

  // Инициализация FCM Push уведомлений (запрос разрешений)
  await PushNotificationService().initialize();

  // Инициализация глобального провайдера синхронизации данных
  final dataSyncProvider = DataSyncProvider();
  dataSyncProvider.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      path: 'assets/translations',
      startLocale: const Locale('uz'),
      fallbackLocale: const Locale('uz'),
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
