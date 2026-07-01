import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/design/choy_tokens.dart';
import '../../../models/booking_model.dart';
import '../../booking/booking_history_screen.dart';

/// 🏠 "Bugungi aktiv bron" banneri (TZ §0.7, B.3.4).
///
/// Joriy foydalanuvchining bugungi `pending`/`confirmed` bronini bosh ekranda
/// ko'rsatadi. Aktiv bron bo'lmasa hech narsa chizmaydi (SizedBox.shrink).
class ActiveBookingBanner extends StatelessWidget {
  const ActiveBookingBanner({super.key});

  String get _today {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      // Bitta maydon bo'yicha so'rov — kompozit indeks talab qilmaydi.
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final today = _today;
        final active = snapshot.data!.docs
            .map((d) => BookingModel.fromFirestore(d))
            .where((b) =>
                b.bookingDate == today && (b.isPending || b.isConfirmed))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        if (active.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
              ChoySpace.xl, ChoySpace.xl, ChoySpace.xl, 0),
          child: _BannerCard(booking: active.first),
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final confirmed = booking.isConfirmed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: ChoyRadius.all(ChoyRadius.xl),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(ChoySpace.lg),
          decoration: BoxDecoration(
            gradient: ChoyPalette.teaGradient,
            borderRadius: ChoyRadius.all(ChoyRadius.xl),
            boxShadow: [
              BoxShadow(
                color: ChoyPalette.tea.withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: ChoyRadius.all(ChoyRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          confirmed
                              ? Icons.check_circle_rounded
                              : Icons.hourglass_top_rounded,
                          size: 14,
                          color: confirmed
                              ? ChoyPalette.goldLight
                              : Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          confirmed
                              ? 'booking_status_confirmed'.tr()
                              : 'booking_status_pending'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'active_booking_today'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ChoySpace.md),
              Text(
                booking.choyxonaName.isEmpty
                    ? 'choyxona'.tr()
                    : booking.choyxonaName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: ChoySpace.md),
              Wrap(
                spacing: ChoySpace.lg,
                runSpacing: ChoySpace.sm,
                children: [
                  _MetaItem(
                    icon: Icons.access_time_rounded,
                    label: booking.bookingTime ??
                        (booking.timeSlot == 'evening'
                            ? 'time_slot_evening'.tr()
                            : 'time_slot_morning'.tr()),
                  ),
                  _MetaItem(
                    icon: Icons.people_alt_rounded,
                    label: '${booking.guestCount} ${'guests_short'.tr()}',
                  ),
                  if (confirmed && (booking.roomNumber?.isNotEmpty ?? false))
                    _MetaItem(
                      icon: Icons.meeting_room_rounded,
                      label:
                          '${'room'.tr()} ${booking.roomNumber}',
                      highlight: true,
                    ),
                ],
              ),
              const SizedBox(height: ChoySpace.md),
              Row(
                children: [
                  Text(
                    confirmed
                        ? 'active_booking_confirmed_hint'.tr()
                        : 'active_booking_pending_hint'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? ChoyPalette.goldLight : Colors.white;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
