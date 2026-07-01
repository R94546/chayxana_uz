import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/design/choy_components.dart';
import '../../core/design/choy_tokens.dart';
import '../../services/auth_service.dart';

/// 🔔 Bildirishnomalar ro'yxati — premium redizayn + lokalizatsiya (Faza 4/5).
class NotificationsListScreen extends StatelessWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text('notifications'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () => _markAllAsRead(context),
            tooltip: 'mark_all_read'.tr(),
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _getCurrentUserId(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: userSnapshot.data)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ChoyEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'notifications_load_error'.tr(),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: c.primary));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return ChoyEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'no_notifications'.tr(),
                  message: 'no_notifications_hint'.tr(),
                );
              }

              // Sort locally by createdAt descending (indekssiz)
              final notifications = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final aTime =
                      (a.data() as Map)['createdAt'] as Timestamp?;
                  final bTime =
                      (b.data() as Map)['createdAt'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

              return ListView.builder(
                padding: const EdgeInsets.all(ChoySpace.lg),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationCard(
                    notificationId: notification.id,
                    data: notification.data() as Map<String, dynamic>,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _getCurrentUserId() async {
    final user = await AuthService().getCurrentUserData();
    return user?.userId;
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('all_marked_read'.tr()),
            backgroundColor: ChoyPalette.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: ChoyPalette.danger,
          ),
        );
      }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> data;

  const _NotificationCard({required this.notificationId, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    final isRead = data['isRead'] ?? false;
    final type = (data['type'] ?? 'info').toString();
    final title = (data['title'] ?? 'notification_default'.tr()).toString();
    final body = (data['body'] ?? '').toString();
    final createdAt = data['createdAt'] as Timestamp?;
    final typeColor = _getTypeColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: ChoySpace.md),
      decoration: BoxDecoration(
        color: isRead ? c.surface : c.primaryContainer,
        borderRadius: ChoyRadius.all(ChoyRadius.lg),
        border: Border.all(color: isRead ? c.border : c.primary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: ChoyRadius.all(ChoyRadius.lg),
          onTap: () => _markAsRead(),
          child: Padding(
            padding: const EdgeInsets.all(ChoySpace.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: ChoyRadius.all(ChoyRadius.md),
                  ),
                  child: Icon(_getTypeIcon(type), color: typeColor, size: 22),
                ),
                const SizedBox(width: ChoySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: c.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(body,
                            style: TextStyle(
                                color: c.textSecondary, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      if (createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(_formatTime(context, createdAt.toDate()),
                            style:
                                TextStyle(color: c.textMuted, fontSize: 11)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'new_booking':
      case 'booking':
      case 'booking_confirmed':
      case 'booking_status_update':
        return Icons.event_available_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'review':
        return Icons.comment_rounded;
      case 'new_order':
      case 'order_added':
        return Icons.restaurant_menu_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'system':
        return Icons.settings_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'new_booking':
      case 'booking':
      case 'booking_confirmed':
      case 'booking_status_update':
        return ChoyPalette.success;
      case 'favorite':
        return ChoyPalette.danger;
      case 'review':
        return ChoyPalette.info;
      case 'new_order':
      case 'order_added':
        return ChoyPalette.gold;
      case 'promo':
        return ChoyPalette.warning;
      default:
        return ChoyPalette.tea;
    }
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'time_just_now'.tr();
    if (diff.inHours < 1) return 'time_min_ago'.tr(args: ['${diff.inMinutes}']);
    if (diff.inDays < 1) return 'time_hours_ago'.tr(args: ['${diff.inHours}']);
    if (diff.inDays < 7) return 'time_days_ago'.tr(args: ['${diff.inDays}']);
    return DateFormat('d MMM, HH:mm', context.locale.languageCode)
        .format(dateTime);
  }

  Future<void> _markAsRead() async {
    if (data['isRead'] == true) return;
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }
}
