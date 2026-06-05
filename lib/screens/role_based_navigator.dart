import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'navigation/main_navigation_screen.dart';
import 'superadmin/super_admin_dashboard.dart';
import 'choyxona_admin/choyxona_admin_dashboard.dart';

/// Навигатор по ролям - направляет пользователя на нужный экран в зависимости от роли
class RoleBasedNavigator extends StatefulWidget {
  const RoleBasedNavigator({super.key});

  @override
  State<RoleBasedNavigator> createState() => _RoleBasedNavigatorState();
}

class _RoleBasedNavigatorState extends State<RoleBasedNavigator> {
  bool _isLoading = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    _determineScreen();
  }

  Future<void> _determineScreen() async {
    try {
      final authService = AuthService();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        // Не авторизован
        setState(() {
          _targetScreen = const LoginScreen();
          _isLoading = false;
        });
        return;
      }

      // Получить данные пользователя
      final userData = await authService.getCurrentUserData();

      if (userData == null) {
        setState(() {
          _targetScreen = const LoginScreen();
          _isLoading = false;
        });
        return;
      }

      // Определить экран по роли
      Widget screen;
      switch (userData.role) {
        case UserRole.superAdmin:
          screen = const SuperAdminDashboard();
          break;
        case UserRole.choyxonaAdmin:
        case UserRole.choyxonaOwner:
          screen = const ChoyxonaAdminDashboard();
          break;
        default:
          screen = const MainNavigationScreen();
      }

      setState(() {
        _targetScreen = screen;
        _isLoading = false;
      });
    } catch (e) {
      print('Error determining screen: $e');
      setState(() {
        _targetScreen = const LoginScreen();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              const Text('Загрузка...'),
            ],
          ),
        ),
      );
    }

    return _targetScreen ?? const LoginScreen();
  }
}

/// Навигатор после входа - используется в LoginScreen
class PostLoginNavigator {
  /// Перейти на нужный экран после входа
  static Future<void> navigate(BuildContext context) async {
    try {
      final authService = AuthService();
      final userData = await authService.getCurrentUserData();

      if (userData == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
        return;
      }

      Widget screen;
      switch (userData.role) {
        case UserRole.superAdmin:
          screen = const SuperAdminDashboard();
          break;
        case UserRole.choyxonaAdmin:
        case UserRole.choyxonaOwner:
          screen = const ChoyxonaAdminDashboard();
          break;
        default:
          screen = const MainNavigationScreen();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => screen),
        (route) => false,
      );
    } catch (e) {
      print('Error navigating: $e');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }
}
