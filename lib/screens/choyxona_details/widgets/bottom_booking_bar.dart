import 'package:flutter/material.dart';
import '../../../models/choyxona_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/ultra_button.dart';
import '../../../widgets/hero_page_route.dart';
import '../../booking/booking_screen.dart';

class BottomBookingBar extends StatelessWidget {
  final Choyxona choyxona;

  const BottomBookingBar({
    super.key,
    required this.choyxona,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: (isDark ? AppColors.darkBorder : AppColors.border),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: UltraButton(
            text: 'Book a Table',
            icon: Icons.event_available,
            onPressed: () {
              Navigator.of(context).push(
                FadeThroughPageRoute(
                  page: BookingScreen(choyxona: choyxona),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
