import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/design/choy_components.dart';
import '../../core/design/choy_tokens.dart';
import '../../models/booking_model.dart';
import '../../models/choyxona_model.dart';
import '../../models/room_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/push_notification_service.dart';

/// 🍵 Bron ekrani — kun-asosli + xona tanlash (TZ B.2/B.3.3, Faza 4 redizayn).
class BookingScreen extends StatefulWidget {
  final Choyxona choyxona;

  const BookingScreen({super.key, required this.choyxona});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _bookingService = BookingService();
  final _specialRequestsController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = 'morning'; // kelish vaqti (informatsion)
  int _guestCount = 2;

  String? _selectedRoomId;
  bool _letAdminChoose = false;

  List<RoomModel> _rooms = [];
  // Sana bo'yicha band xona id'lari: {'2026-06-27': {roomIdA, roomIdB}}
  Map<String, Set<String>> _occupiedByDate = {};

  bool _isDataLoading = true;
  bool _isSubmitting = false;

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  int get _totalRooms => _rooms.isNotEmpty
      ? _rooms.where((r) => !r.isUnavailable).length
      : (widget.choyxona.roomCount > 0 ? widget.choyxona.roomCount : 0);

  @override
  void initState() {
    super.initState();
    _loadData();
    _prefillContact();
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _prefillContact() async {
    final user = await AuthService().getCurrentUserData();
    if (user != null && mounted) {
      _nameController.text =
          user.fullName.trim().isNotEmpty ? user.fullName.trim() : user.email;
      _phoneController.text = user.phone;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isDataLoading = true);
    try {
      final fs = FirebaseFirestore.instance;
      final roomsSnap = await fs
          .collection('rooms')
          .where('choyxonaId', isEqualTo: widget.choyxona.id)
          .get();
      final locksSnap = await fs
          .collection('room_locks')
          .where('choyxonaId', isEqualTo: widget.choyxona.id)
          .get();

      final rooms = roomsSnap.docs
          .map((d) => RoomModel.fromFirestore(d))
          .toList()
        ..sort((a, b) => a.number.compareTo(b.number));

      final occupied = <String, Set<String>>{};
      for (final d in locksSnap.docs) {
        final data = d.data();
        final date = data['bookingDate'] as String? ?? '';
        final roomId = data['roomId'] as String? ?? '';
        if (date.isEmpty || roomId.isEmpty) continue;
        occupied.putIfAbsent(date, () => <String>{}).add(roomId);
      }

      if (mounted) {
        setState(() {
          _rooms = rooms;
          _occupiedByDate = occupied;
          _isDataLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isDataLoading = false);
    }
  }

  Set<String> _occupiedOn(String date) => _occupiedByDate[date] ?? <String>{};

  int _freeRoomsOn(String date) {
    if (_rooms.isNotEmpty) {
      return _rooms
          .where((r) => !r.isUnavailable && !_occupiedOn(date).contains(r.id))
          .length;
    }
    return (_totalRooms - _occupiedOn(date).length).clamp(0, _totalRooms);
  }

  /// Tanlangan sana + mehmonlar soniga mos bo'sh xonalar.
  List<RoomModel> get _selectableRooms {
    final occ = _occupiedOn(_dateStr);
    return _rooms
        .where((r) =>
            !r.isUnavailable &&
            !occ.contains(r.id) &&
            r.capacity >= _guestCount)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text('book_table'.tr())),
      body: _isDataLoading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : ListView(
              padding: const EdgeInsets.all(ChoySpace.lg),
              children: [
                _ChoyxonaInfo(choyxona: widget.choyxona, totalRooms: _totalRooms),
                const SizedBox(height: ChoySpace.xxl),
                _stepLabel(c, '1', 'select_date'.tr()),
                const SizedBox(height: ChoySpace.md),
                _buildDateSelector(c),
                const SizedBox(height: ChoySpace.xxl),
                _stepLabel(c, '2', 'arrival_time'.tr()),
                const SizedBox(height: ChoySpace.md),
                _buildSlotSelector(c),
                const SizedBox(height: ChoySpace.xxl),
                _stepLabel(c, '3', 'guest_count'.tr()),
                const SizedBox(height: ChoySpace.md),
                _buildGuestCount(c),
                const SizedBox(height: ChoySpace.xxl),
                _stepLabel(c, '4', 'select_room'.tr()),
                const SizedBox(height: ChoySpace.md),
                _buildRoomSelection(c),
                const SizedBox(height: ChoySpace.xxl),
                _stepLabel(c, '5', 'contact_info'.tr()),
                const SizedBox(height: ChoySpace.md),
                _buildContactFields(c),
                const SizedBox(height: ChoySpace.lg),
                TextField(
                  controller: _specialRequestsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'special_requests_placeholder'.tr(),
                  ),
                ),
                const SizedBox(height: ChoySpace.xxl),
                _buildSubmit(c),
                const SizedBox(height: ChoySpace.xxl),
              ],
            ),
    );
  }

  Widget _stepLabel(ChoyColors c, String n, String title) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(n,
              style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ),
        const SizedBox(width: ChoySpace.sm),
        Text(title,
            style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
      ],
    );
  }

  Widget _buildDateSelector(ChoyColors c) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        separatorBuilder: (_, __) => const SizedBox(width: ChoySpace.sm),
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final isSelected = _dateStr == dateStr;
          final free = _freeRoomsOn(dateStr);
          final isFull = free <= 0;
          final accent = isFull ? ChoyPalette.danger : ChoyPalette.success;

          return GestureDetector(
            onTap: isFull
                ? null
                : () => setState(() {
                      _selectedDate = date;
                      _selectedRoomId = null;
                    }),
            child: Container(
              width: 68,
              decoration: BoxDecoration(
                color: isSelected
                    ? c.primary
                    : (isFull
                        ? c.surfaceVariant
                        : c.surface),
                borderRadius: ChoyRadius.all(ChoyRadius.lg),
                border: Border.all(
                    color: isSelected ? c.primary : c.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', context.locale.languageCode)
                        .format(date)
                        .toUpperCase(),
                    style: TextStyle(
                        color: isSelected ? Colors.white : c.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                        color: isSelected ? Colors.white : c.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotSelector(ChoyColors c) {
    Widget tile(String slot, IconData icon, String title, String time) {
      final selected = _selectedSlot == slot;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedSlot = slot),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: ChoySpace.lg),
            decoration: BoxDecoration(
              color: selected ? c.primaryContainer : c.surface,
              borderRadius: ChoyRadius.all(ChoyRadius.lg),
              border: Border.all(
                  color: selected ? c.primary : c.border,
                  width: selected ? 1.6 : 1),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 28,
                    color: selected ? c.primary : c.textMuted),
                const SizedBox(height: 6),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? c.primary : c.textPrimary)),
                Text(time,
                    style: TextStyle(fontSize: 12, color: c.textMuted)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('morning', Icons.wb_sunny_rounded, 'time_slot_day'.tr(),
            '08:00 - 16:00'),
        const SizedBox(width: ChoySpace.md),
        tile('evening', Icons.nights_stay_rounded, 'time_slot_night'.tr(),
            '16:00 - 00:00'),
      ],
    );
  }

  Widget _buildGuestCount(ChoyColors c) {
    return ChoyCard(
      child: Row(
        children: [
          Icon(Icons.people_alt_rounded, color: c.primary),
          const SizedBox(width: ChoySpace.md),
          Text('$_guestCount ${'guests_short'.tr()}',
              style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const Spacer(),
          _roundBtn(c, Icons.remove_rounded, _guestCount > 1, () {
            setState(() {
              _guestCount--;
              if (_selectedRoomId != null &&
                  !_selectableRooms.any((r) => r.id == _selectedRoomId)) {
                _selectedRoomId = null;
              }
            });
          }),
          SizedBox(
            width: 40,
            child: Text(_guestCount.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ),
          _roundBtn(c, Icons.add_rounded, _guestCount < 20, () {
            setState(() {
              _guestCount++;
              if (_selectedRoomId != null &&
                  !_selectableRooms.any((r) => r.id == _selectedRoomId)) {
                _selectedRoomId = null;
              }
            });
          }),
        ],
      ),
    );
  }

  Widget _roundBtn(ChoyColors c, IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: ChoyRadius.all(ChoyRadius.pill),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled ? c.primaryContainer : c.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 20, color: enabled ? c.primary : c.textMuted),
      ),
    );
  }

  Widget _buildRoomSelection(ChoyColors c) {
    // Xonalar sozlanmagan — admin biriktiradi
    if (_rooms.isEmpty) {
      return ChoyCard(
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: c.accent),
            const SizedBox(width: ChoySpace.md),
            Expanded(
              child: Text('admin_will_assign_room'.tr(),
                  style: TextStyle(color: c.textSecondary, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    final occ = _occupiedOn(_dateStr);
    final selectable = _selectableRooms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${selectable.length} ${'rooms_free_count'.tr()}',
          style: TextStyle(
              color: selectable.isEmpty ? ChoyPalette.danger : c.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: ChoySpace.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: ChoySpace.md,
          crossAxisSpacing: ChoySpace.md,
          childAspectRatio: 1.55,
          children: _rooms.map((room) {
            final isOccupied = occ.contains(room.id);
            final tooSmall = room.capacity < _guestCount;
            final disabled = isOccupied || tooSmall || room.isUnavailable;
            final selected = _selectedRoomId == room.id;
            return _RoomTile(
              room: room,
              selected: selected,
              disabled: disabled,
              isOccupied: isOccupied,
              tooSmall: tooSmall,
              onTap: disabled
                  ? null
                  : () => setState(() {
                        _selectedRoomId = room.id;
                        _letAdminChoose = false;
                      }),
            );
          }).toList(),
        ),
        const SizedBox(height: ChoySpace.md),
        // "Admin tanlasin" varianti (TZ Q3)
        GestureDetector(
          onTap: selectable.isEmpty
              ? null
              : () => setState(() {
                    _letAdminChoose = true;
                    _selectedRoomId = null;
                  }),
          child: Container(
            padding: const EdgeInsets.all(ChoySpace.md),
            decoration: BoxDecoration(
              color: _letAdminChoose ? c.primaryContainer : c.surface,
              borderRadius: ChoyRadius.all(ChoyRadius.md),
              border: Border.all(
                  color: _letAdminChoose ? c.primary : c.border,
                  width: _letAdminChoose ? 1.6 : 1),
            ),
            child: Row(
              children: [
                Icon(
                    _letAdminChoose
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _letAdminChoose ? c.primary : c.textMuted,
                    size: 20),
                const SizedBox(width: ChoySpace.md),
                Expanded(
                  child: Text('let_admin_choose'.tr(),
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactFields(ChoyColors c) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'your_name'.tr(),
            prefixIcon: const Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: ChoySpace.md),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'your_phone'.tr(),
            hintText: '+998 90 123 45 67',
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmit(ChoyColors c) {
    final hasRooms = _rooms.isNotEmpty;
    final roomChosen = _selectedRoomId != null || _letAdminChoose;
    final canSubmit = _freeRoomsOn(_dateStr) > 0 &&
        (!hasRooms || roomChosen) &&
        !_isSubmitting;

    return ChoyButton(
      label: 'confirm_booking'.tr(),
      icon: Icons.event_available_rounded,
      loading: _isSubmitting,
      onPressed: canSubmit ? _submit : null,
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.replaceAll(' ', '').replaceAll('-', '');

    if (name.isEmpty) {
      _snack('your_name'.tr(), error: true);
      return;
    }
    if (!RegExp(r'^\+998\d{9}$').hasMatch(phone)) {
      _snack('phone_invalid'.tr(), error: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = await AuthService().getCurrentUserData();
      if (user == null) {
        _snack('not_authorized'.tr(), error: true);
        setState(() => _isSubmitting = false);
        return;
      }

      final now = DateTime.now();
      RoomModel? room;
      if (_selectedRoomId != null) {
        room = _rooms.firstWhere((r) => r.id == _selectedRoomId);
      }

      final booking = BookingModel(
        bookingId: '',
        userId: user.userId,
        choyxonaId: widget.choyxona.id,
        choyxonaName: widget.choyxona.name,
        bookingDate: _dateStr,
        bookingTime: null,
        duration: 480,
        guestCount: _guestCount,
        guestName: name,
        guestPhone: phone,
        guestEmail: user.email,
        specialRequests: _specialRequestsController.text.trim(),
        status: 'pending',
        paymentStatus: 'unpaid',
        paymentMethod: 'cash',
        roomId: room?.id,
        roomNumber: room?.number,
        timeSlot: _selectedSlot,
        hasOrder: false,
        isRated: false,
        createdAt: now,
        updatedAt: now,
      );

      final error = await _bookingService.createBooking(booking);

      if (!mounted) return;
      if (error != null) {
        _snack(error, error: true);
        // Bandlik o'zgargan bo'lishi mumkin — qayta yuklaymiz
        await _loadData();
        setState(() => _isSubmitting = false);
        return;
      }

      await _notifyAdmins(name);
      if (!mounted) return;
      _snack('booking_success'.tr());
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('${'error'.tr()}: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _notifyAdmins(String guestName) async {
    try {
      final admins = await FirebaseFirestore.instance
          .collection('users')
          .where('choyxonaId', isEqualTo: widget.choyxona.id)
          .where('role', isEqualTo: 'choyxona_admin')
          .get();
      final slotText = _selectedSlot == 'morning'
          ? 'time_slot_day'.tr()
          : 'time_slot_night'.tr();
      for (final admin in admins.docs) {
        await PushNotificationService().sendNotificationToUser(
          userId: admin.id,
          title: 'Yangi bron! 📅',
          body:
              '$guestName · ${widget.choyxona.name} · $_dateStr · $slotText · $_guestCount ${'guests_short'.tr()}',
          data: {'type': 'new_booking', 'choyxonaId': widget.choyxona.id},
        );
      }
    } catch (_) {}
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? ChoyPalette.danger : ChoyPalette.success,
      ),
    );
  }
}

/// Choyxona ma'lumot kartasi (bron sarlavhasi).
class _ChoyxonaInfo extends StatelessWidget {
  const _ChoyxonaInfo({required this.choyxona, required this.totalRooms});
  final Choyxona choyxona;
  final int totalRooms;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    final img = choyxona.images.isNotEmpty &&
            choyxona.images.first.startsWith('http')
        ? choyxona.images.first
        : null;
    return ChoyCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: ChoyRadius.all(ChoyRadius.md),
            child: SizedBox(
              width: 56,
              height: 56,
              child: img != null
                  ? Image.network(img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: c.surfaceVariant,
                          child: Icon(Icons.local_cafe_rounded,
                              color: c.textMuted)))
                  : Container(
                      color: c.surfaceVariant,
                      child: Icon(Icons.local_cafe_rounded,
                          color: c.textMuted)),
            ),
          ),
          const SizedBox(width: ChoySpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(choyxona.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.meeting_room_rounded,
                        size: 14, color: ChoyPalette.success),
                    const SizedBox(width: 4),
                    Text('$totalRooms ${'rooms_total'.tr()}',
                        style: TextStyle(
                            color: c.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Xona kartasi (sig'im + band/bo'sh holati — TZ B.5.2).
class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.selected,
    required this.disabled,
    required this.isOccupied,
    required this.tooSmall,
    required this.onTap,
  });

  final RoomModel room;
  final bool selected;
  final bool disabled;
  final bool isOccupied;
  final bool tooSmall;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    final Color accent = isOccupied
        ? ChoyPalette.roomBusy
        : (tooSmall ? ChoyPalette.roomUnavailable : ChoyPalette.roomFree);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(ChoySpace.md),
          decoration: BoxDecoration(
            color: selected ? c.primaryContainer : c.surface,
            borderRadius: ChoyRadius.all(ChoyRadius.lg),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.meeting_room_rounded,
                      size: 18, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      room.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded,
                        size: 18, color: c.primary),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.people_alt_rounded,
                      size: 15, color: c.textMuted),
                  const SizedBox(width: 4),
                  Text('${room.capacity}',
                      style: TextStyle(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const Spacer(),
                  Text(
                    isOccupied
                        ? 'room_busy'.tr()
                        : (tooSmall ? 'room_too_small'.tr() : 'room_free'.tr()),
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
