import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/adaptive_scaffold.dart';
import '../home/home_screen.dart';
import '../map/map_screen.dart';
import '../favorites/favorites_screen.dart';
import '../booking/booking_history_screen.dart';
import '../profile/profile_screen.dart';

/// Главный экран с адаптивной навигацией
/// Mobile: Bottom Navigation Bar
/// Desktop: Collapsible Sidebar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 5 основных экранов: Главная, Карта, Избранное, Заказы, Профиль
  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
    FavoritesScreen(),
    BookingHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onIndexChanged: (index) => setState(() => _currentIndex = index),
      destinations: [
        AdaptiveDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'home'.tr(),
        ),
        AdaptiveDestination(
          icon: Icons.map_outlined,
          selectedIcon: Icons.map,
          label: 'map_view'.tr(),
        ),
        AdaptiveDestination(
          icon: Icons.favorite_outline,
          selectedIcon: Icons.favorite,
          label: 'favorites'.tr(),
        ),
        AdaptiveDestination(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: 'orders'.tr(),
        ),
        AdaptiveDestination(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'profile'.tr(),
        ),
      ],
      screens: _screens,
    );
  }
}
