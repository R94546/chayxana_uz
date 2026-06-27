import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/design/choy_components.dart';
import '../../core/design/choy_tokens.dart';
import '../../models/room_model.dart';
import '../../services/booking_service.dart';
import 'admin_add_order_screen.dart';

/// 🍵 Admin — bronlar (tasdiqlash + xona biriktirish), Faza 4 redizayn.
class ChoyxonaBookingsScreen extends StatefulWidget {
  final String choyxonaId;
  const ChoyxonaBookingsScreen({super.key, required this.choyxonaId});

  @override
  State<ChoyxonaBookingsScreen> createState() =>
      _ChoyxonaBookingsScreenState();
}

class _ChoyxonaBookingsScreenState extends State<ChoyxonaBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = BookingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _autoCompleteExpiredBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _autoCompleteExpiredBookings() async {
    try {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .where('status', isEqualTo: 'confirmed')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      int n = 0;
      for (final doc in snapshot.docs) {
        final date = doc.data()['bookingDate'] as String? ?? '';
        if (date.isNotEmpty && date.compareTo(todayStr) < 0) {
          batch.update(doc.reference, {
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
            'completedAt': FieldValue.serverTimestamp(),
            'completedBy': 'auto',
          });
          n++;
        }
      }
      if (n > 0) await batch.commit();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text('bookings'.tr()),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: c.primary,
          unselectedLabelColor: c.textMuted,
          indicatorColor: c.primary,
          tabs: [
            Tab(text: 'booking_status_pending'.tr()),
            Tab(text: 'booking_status_confirmed'.tr()),
            Tab(text: 'booking_status_completed'.tr()),
            Tab(text: 'booking_status_cancelled'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('pending'),
          _buildList('confirmed'),
          _buildList('completed'),
          _buildList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildList(String status) {
    final c = ChoyColors.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: c.primary));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return ChoyEmptyState(
            icon: Icons.event_note_rounded,
            title: 'no_bookings_status'.tr(),
          );
        }
        // createdAt bo'yicha saralash (indekssiz)
        docs.sort((a, b) {
          final at = (a.data() as Map)['createdAt'] as Timestamp?;
          final bt = (b.data() as Map)['createdAt'] as Timestamp?;
          return (bt?.compareTo(at ?? Timestamp(0, 0))) ?? 0;
        });
        return ListView.builder(
          padding: const EdgeInsets.all(ChoySpace.lg),
          itemCount: docs.length,
          itemBuilder: (context, i) => _BookingCard(
            id: docs[i].id,
            data: docs[i].data() as Map<String, dynamic>,
            status: status,
            onConfirm: () => _onConfirm(docs[i].id,
                docs[i].data() as Map<String, dynamic>),
            onReject: () => _onReject(docs[i].id,
                docs[i].data() as Map<String, dynamic>),
            onComplete: () => _onComplete(docs[i].id,
                docs[i].data() as Map<String, dynamic>),
            onAddOrder: () => _openAddOrder(docs[i].id,
                docs[i].data() as Map<String, dynamic>),
          ),
        );
      },
    );
  }

  Future<void> _onConfirm(String id, Map<String, dynamic> data) async {
    final hasRoom = (data['roomId'] as String?)?.isNotEmpty ?? false;
    if (hasRoom) {
      final err = await _service.confirmBooking(id);
      if (err != null) return _snack(err, error: true);
      // Mijozga xabar onBookingStatusChanged CF orqali (server-side) yuboriladi.
      _snack('booking_confirmed_msg'.tr());
      return;
    }
    // Xona tanlanmagan — admin tanlaydi
    final room = await _pickRoom(data);
    if (room == null) return;
    final err = await _service.assignRoomAndConfirm(
      bookingId: id,
      roomId: room.id,
      roomNumber: room.number,
      choyxonaId: widget.choyxonaId,
      bookingDate: data['bookingDate'] as String? ?? '',
    );
    if (err != null) return _snack(err, error: true);
    _snack('booking_confirmed_msg'.tr());
  }

  /// Bo'sh xonalar ro'yxatidan tanlash (bottom sheet).
  Future<RoomModel?> _pickRoom(Map<String, dynamic> data) async {
    final c = ChoyColors.of(context);
    final date = data['bookingDate'] as String? ?? '';
    final guests = (data['guestCount'] as num?)?.toInt() ?? 1;

    final fs = FirebaseFirestore.instance;
    final roomsSnap = await fs
        .collection('rooms')
        .where('choyxonaId', isEqualTo: widget.choyxonaId)
        .get();
    final locksSnap = await fs
        .collection('room_locks')
        .where('choyxonaId', isEqualTo: widget.choyxonaId)
        .where('bookingDate', isEqualTo: date)
        .get();
    final occupied = locksSnap.docs
        .map((d) => (d.data())['roomId'] as String? ?? '')
        .toSet();
    final rooms = roomsSnap.docs
        .map((d) => RoomModel.fromFirestore(d))
        .where((r) => !r.isUnavailable && !occupied.contains(r.id))
        .toList()
      ..sort(RoomModel.compareByNumber);

    if (!mounted) return null;
    if (rooms.isEmpty) {
      _snack('no_free_rooms'.tr(), error: true);
      return null;
    }

    return showModalBottomSheet<RoomModel>(
      context: context,
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ChoyRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ChoySpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('assign_room_title'.tr(),
                  style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
              const SizedBox(height: ChoySpace.md),
              ...rooms.map((r) {
                final tooSmall = r.capacity < guests;
                return ListTile(
                  enabled: !tooSmall,
                  leading: Icon(Icons.meeting_room_rounded,
                      color: tooSmall ? c.textMuted : ChoyPalette.roomFree),
                  title: Text(r.displayName,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${r.capacity} ${'guests_short'.tr()}${tooSmall ? ' · ${'room_too_small'.tr()}' : ''}',
                      style: TextStyle(color: c.textMuted, fontSize: 12)),
                  trailing:
                      Icon(Icons.chevron_right_rounded, color: c.textMuted),
                  onTap: tooSmall ? null : () => Navigator.pop(context, r),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onReject(String id, Map<String, dynamic> data) async {
    final err = await _service.updateBookingStatus(
        bookingId: id, status: 'cancelled');
    if (err != null) return _snack(err, error: true);
    _snack('booking_rejected_msg'.tr());
  }

  Future<void> _onComplete(String id, Map<String, dynamic> data) async {
    final err = await _service.completeBooking(id);
    if (err != null) return _snack(err, error: true);
    _snack('booking_completed_msg'.tr());
  }

  void _openAddOrder(String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAddOrderScreen(
          bookingId: id,
          choyxonaId: widget.choyxonaId,
          userId: data['userId'] ?? '',
          roomNumber: data['roomNumber'] as String?,
        ),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? ChoyPalette.danger : ChoyPalette.success,
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.id,
    required this.data,
    required this.status,
    required this.onConfirm,
    required this.onReject,
    required this.onComplete,
    required this.onAddOrder,
  });

  final String id;
  final Map<String, dynamic> data;
  final String status;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onComplete;
  final VoidCallback onAddOrder;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    final date = data['bookingDate'] ?? '';
    final slot = data['timeSlot'] as String? ?? '';
    final slotText = slot == 'morning'
        ? 'time_slot_day'.tr()
        : (slot == 'evening' ? 'time_slot_night'.tr() : '—');
    final guests = (data['guestCount'] as num?)?.toInt() ?? 0;
    final roomNumber = data['roomNumber'] as String?;
    final notes = (data['specialRequests'] ?? '').toString();
    final guestName =
        (data['guestName']?.toString().trim().isNotEmpty == true)
            ? data['guestName'].toString()
            : 'guest'.tr();
    final phone = data['guestPhone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: ChoySpace.md),
      child: ChoyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: c.primaryContainer,
                  child: Icon(Icons.person_rounded, color: c.primary),
                ),
                const SizedBox(width: ChoySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guestName,
                          style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      if (phone.isNotEmpty)
                        Text(phone,
                            style: TextStyle(
                                color: c.primary, fontSize: 13)),
                    ],
                  ),
                ),
                _statusBadge(),
              ],
            ),
            const SizedBox(height: ChoySpace.md),
            Divider(color: c.border, height: 1),
            const SizedBox(height: ChoySpace.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _info(c, Icons.calendar_today_rounded, date, 'select_date'.tr()),
                _info(c, Icons.access_time_rounded, slotText,
                    'arrival_time'.tr()),
                _info(c, Icons.people_alt_rounded, '$guests',
                    'guests_short'.tr()),
                if (roomNumber != null && roomNumber.isNotEmpty)
                  _info(c, Icons.meeting_room_rounded, roomNumber,
                      'room'.tr()),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: ChoySpace.md),
              Container(
                padding: const EdgeInsets.all(ChoySpace.md),
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: ChoyRadius.all(ChoyRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_rounded, size: 16, color: c.textMuted),
                    const SizedBox(width: ChoySpace.sm),
                    Expanded(
                      child: Text(notes,
                          style: TextStyle(
                              color: c.textSecondary, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: ChoySpace.lg),
              Row(
                children: [
                  Expanded(
                    child: ChoyButton(
                      label: 'reject'.tr(),
                      variant: ChoyButtonVariant.ghost,
                      onPressed: onReject,
                    ),
                  ),
                  const SizedBox(width: ChoySpace.md),
                  Expanded(
                    child: ChoyButton(
                      label: 'confirm'.tr(),
                      icon: Icons.check_rounded,
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'confirmed') ...[
              const SizedBox(height: ChoySpace.lg),
              Row(
                children: [
                  Expanded(
                    child: ChoyButton(
                      label: 'add_food'.tr(),
                      icon: Icons.restaurant_menu_rounded,
                      variant: ChoyButtonVariant.secondary,
                      onPressed: onAddOrder,
                    ),
                  ),
                  const SizedBox(width: ChoySpace.md),
                  Expanded(
                    child: ChoyButton(
                      label: 'finish'.tr(),
                      onPressed: onComplete,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(ChoyColors c, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: c.primary),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        Text(label,
            style: TextStyle(color: c.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _statusBadge() {
    switch (status) {
      case 'confirmed':
        return ChoyStatusBadge(
            label: 'booking_status_confirmed'.tr(),
            tone: ChoyStatusTone.success);
      case 'cancelled':
        return ChoyStatusBadge(
            label: 'booking_status_cancelled'.tr(),
            tone: ChoyStatusTone.danger);
      case 'completed':
        return ChoyStatusBadge(
            label: 'booking_status_completed'.tr(),
            tone: ChoyStatusTone.info);
      default:
        return ChoyStatusBadge(
            label: 'booking_status_pending'.tr(),
            tone: ChoyStatusTone.warning);
    }
  }
}
