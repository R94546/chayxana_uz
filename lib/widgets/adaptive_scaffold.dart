import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';

/// 🖥️ Adaptive Scaffold with Collapsible Sidebar
/// Mobile: Bottom Navigation Bar
/// Desktop: Collapsible Navigation Rail (Sidebar)
class AdaptiveScaffold extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<AdaptiveDestination> destinations;
  final List<Widget> screens;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.destinations,
    required this.screens,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  bool _isRailExtended = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Desktop/Web: Use NavigationRail (collapsible sidebar)
    if (ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context)) {
      return Scaffold(
        body: Row(
          children: [
            // Collapsible Sidebar
            _buildNavigationRail(context, isDark),
            
            // Vertical Divider
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
            
            // Main Content
            Expanded(
              child: widget.screens[widget.currentIndex],
            ),
          ],
        ),
        floatingActionButton: widget.floatingActionButton,
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
      );
    }

    // Mobile: Use Bottom Navigation Bar
    return Scaffold(
      body: widget.screens[widget.currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(context, isDark),
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }

  Widget _buildNavigationRail(BuildContext context, bool isDark) {
    return NavigationRail(
      extended: _isRailExtended,
      minExtendedWidth: 200,
      backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
      leading: Column(
        children: [
          const SizedBox(height: 8),
          // Toggle button for collapse/expand
          IconButton(
            icon: Icon(
              _isRailExtended ? Icons.menu_open : Icons.menu,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () => setState(() => _isRailExtended = !_isRailExtended),
            tooltip: _isRailExtended ? 'Yig\'ish' : 'Kengaytirish',
          ),
          const SizedBox(height: 8),
          // Logo
          if (_isRailExtended)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'CHOYXONA.UZ',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          const Divider(),
        ],
      ),
      selectedIndex: widget.currentIndex,
      onDestinationSelected: widget.onIndexChanged,
      labelType: _isRailExtended 
          ? NavigationRailLabelType.none 
          : NavigationRailLabelType.selected,
      indicatorColor: Theme.of(context).primaryColor.withOpacity(0.15),
      selectedIconTheme: IconThemeData(
        color: Theme.of(context).primaryColor,
      ),
      unselectedIconTheme: IconThemeData(
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      selectedLabelTextStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      destinations: widget.destinations.map((dest) {
        return NavigationRailDestination(
          icon: Icon(dest.icon),
          selectedIcon: Icon(dest.selectedIcon ?? dest.icon),
          label: Text(dest.label),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadow : AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.destinations.asMap().entries.map((entry) {
              final index = entry.key;
              final dest = entry.value;
              final isSelected = widget.currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onIndexChanged(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withOpacity(0.15) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? (dest.selectedIcon ?? dest.icon) : dest.icon,
                          color: isSelected 
                              ? Theme.of(context).primaryColor 
                              : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dest.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Navigation destination model
class AdaptiveDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const AdaptiveDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}
