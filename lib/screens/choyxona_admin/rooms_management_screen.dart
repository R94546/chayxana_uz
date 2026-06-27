import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/design/choy_components.dart';
import '../../core/design/choy_tokens.dart';
import '../../models/room_model.dart';

/// 🍵 Admin — Xonalar boshqaruvi (rooms CRUD, TZ B.5.2 / "Xona CRUD").
///
/// `rooms` kolleksiyasini boshqaradi (bron oqimi shu kolleksiyadan xona tanlaydi).
/// Bugungi `room_locks` real-time ko'rsatiladi (bugun band xonalar).
class RoomsManagementScreen extends StatelessWidget {
  final String choyxonaId;
  const RoomsManagementScreen({super.key, required this.choyxonaId});

  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text('rooms_management'.tr())),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('add_room'.tr()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .where('choyxonaId', isEqualTo: choyxonaId)
            .snapshots(),
        builder: (context, roomSnap) {
          if (roomSnap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          final rooms = (roomSnap.data?.docs ?? [])
              .map((d) => RoomModel.fromFirestore(d))
              .toList()
            ..sort((a, b) => a.number.compareTo(b.number));

          if (rooms.isEmpty) {
            return ChoyEmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'no_rooms_title'.tr(),
              message: 'no_rooms_message'.tr(),
              action: ChoyButton(
                label: 'add_room'.tr(),
                icon: Icons.add_rounded,
                expanded: false,
                onPressed: () => _openEditor(context),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('room_locks')
                .where('choyxonaId', isEqualTo: choyxonaId)
                .where('bookingDate', isEqualTo: _today)
                .snapshots(),
            builder: (context, lockSnap) {
              final bookedToday = (lockSnap.data?.docs ?? [])
                  .map((d) =>
                      (d.data() as Map<String, dynamic>)['roomId'] as String? ??
                      '')
                  .where((id) => id.isNotEmpty)
                  .toSet();

              final freeCount = rooms
                  .where((r) =>
                      !r.isUnavailable && !bookedToday.contains(r.id))
                  .length;

              return Column(
                children: [
                  _SummaryBar(
                    total: rooms.where((r) => !r.isUnavailable).length,
                    freeToday: freeCount,
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(ChoySpace.lg),
                      mainAxisSpacing: ChoySpace.md,
                      crossAxisSpacing: ChoySpace.md,
                      childAspectRatio: 1.25,
                      children: rooms.map((room) {
                        return _RoomAdminTile(
                          room: room,
                          bookedToday: bookedToday.contains(room.id),
                          onTap: () => _openRoomMenu(context, room),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _openRoomMenu(BuildContext context, RoomModel room) {
    final c = ChoyColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ChoyRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: ChoySpace.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: ChoyRadius.all(ChoyRadius.pill),
              ),
            ),
            const SizedBox(height: ChoySpace.md),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: c.primary),
              title: Text('edit'.tr()),
              onTap: () {
                Navigator.pop(context);
                _openEditor(context, room: room);
              },
            ),
            ListTile(
              leading: Icon(
                  room.isUnavailable
                      ? Icons.check_circle_outline_rounded
                      : Icons.block_rounded,
                  color: room.isUnavailable
                      ? ChoyPalette.success
                      : ChoyPalette.warning),
              title: Text(room.isUnavailable
                  ? 'room_make_available'.tr()
                  : 'room_make_unavailable'.tr()),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(room.id)
                    .update({
                  'status': room.isUnavailable ? 'free' : 'unavailable',
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: ChoyPalette.danger),
              title: Text('delete'.tr(),
                  style: const TextStyle(color: ChoyPalette.danger)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await _confirmDelete(context, room);
                if (ok) {
                  await FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(room.id)
                      .delete();
                }
              },
            ),
            const SizedBox(height: ChoySpace.sm),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, RoomModel room) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('delete_room_title'.tr()),
            content: Text('delete_room_confirm'
                .tr(args: [room.displayName])),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('delete'.tr(),
                    style: const TextStyle(color: ChoyPalette.danger)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _openEditor(BuildContext context, {RoomModel? room}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomEditorSheet(choyxonaId: choyxonaId, room: room),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.total, required this.freeToday});
  final int total;
  final int freeToday;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
          ChoySpace.lg, ChoySpace.lg, ChoySpace.lg, 0),
      padding: const EdgeInsets.all(ChoySpace.lg),
      decoration: BoxDecoration(
        gradient: ChoyPalette.teaGradient,
        borderRadius: ChoyRadius.all(ChoyRadius.lg),
      ),
      child: Row(
        children: [
          _stat('$total', 'rooms_total'.tr()),
          Container(
              width: 1,
              height: 32,
              color: Colors.white.withValues(alpha: 0.3)),
          _stat('$freeToday', 'rooms_free_today'.tr()),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ],
      ),
    );
  }
}

class _RoomAdminTile extends StatelessWidget {
  const _RoomAdminTile({
    required this.room,
    required this.bookedToday,
    required this.onTap,
  });
  final RoomModel room;
  final bool bookedToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    final ChoyStatusTone tone;
    final String label;
    if (room.isUnavailable) {
      tone = ChoyStatusTone.neutral;
      label = 'room_unavailable'.tr();
    } else if (bookedToday) {
      tone = ChoyStatusTone.danger;
      label = 'room_busy_today'.tr();
    } else {
      tone = ChoyStatusTone.success;
      label = 'room_free'.tr();
    }

    return ChoyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(ChoySpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.meeting_room_rounded, color: c.primary, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(room.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
              Icon(Icons.more_vert_rounded, color: c.textMuted, size: 18),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.people_alt_rounded, size: 15, color: c.textMuted),
              const SizedBox(width: 4),
              Text('${room.capacity} ${'guests_short'.tr()}',
                  style:
                      TextStyle(color: c.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: ChoySpace.sm),
          ChoyStatusBadge(label: label, tone: tone),
        ],
      ),
    );
  }
}

/// Xona qo'shish / tahrirlash sheet.
class _RoomEditorSheet extends StatefulWidget {
  const _RoomEditorSheet({required this.choyxonaId, this.room});
  final String choyxonaId;
  final RoomModel? room;

  @override
  State<_RoomEditorSheet> createState() => _RoomEditorSheetState();
}

class _RoomEditorSheetState extends State<_RoomEditorSheet> {
  late final TextEditingController _number;
  late final TextEditingController _name;
  int _capacity = 10;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: widget.room?.number ?? '');
    _name = TextEditingController(text: widget.room?.name ?? '');
    _capacity = widget.room?.capacity ?? 10;
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_number.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('room_number_required'.tr()),
          backgroundColor: ChoyPalette.danger,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final col = FirebaseFirestore.instance.collection('rooms');
    final data = {
      'choyxonaId': widget.choyxonaId,
      'number': _number.text.trim(),
      'name': _name.text.trim(),
      'capacity': _capacity,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    try {
      if (widget.room == null) {
        await col.add({...data, 'status': 'free'});
      } else {
        await col.doc(widget.room!.id).update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ChoyColors.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(ChoySpace.xl),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(ChoyRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.room == null ? 'add_room'.tr() : 'edit_room'.tr(),
              style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
            const SizedBox(height: ChoySpace.lg),
            TextField(
              controller: _number,
              decoration: InputDecoration(
                labelText: 'room_number'.tr(),
                hintText: '1, VIP-2, ${'family_room'.tr()}...',
              ),
            ),
            const SizedBox(height: ChoySpace.md),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: '${'room_name'.tr()} (${'optional'.tr()})',
              ),
            ),
            const SizedBox(height: ChoySpace.lg),
            Row(
              children: [
                Icon(Icons.people_alt_rounded, color: c.primary),
                const SizedBox(width: ChoySpace.md),
                Text('room_capacity'.tr(),
                    style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  onPressed: _capacity > 1
                      ? () => setState(() => _capacity--)
                      : null,
                  icon: Icon(Icons.remove_circle_outline_rounded,
                      color: c.primary),
                ),
                Text('$_capacity',
                    style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                IconButton(
                  onPressed: _capacity < 100
                      ? () => setState(() => _capacity++)
                      : null,
                  icon: Icon(Icons.add_circle_outline_rounded,
                      color: c.primary),
                ),
              ],
            ),
            const SizedBox(height: ChoySpace.xl),
            ChoyButton(
              label: 'save'.tr(),
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: ChoySpace.sm),
          ],
        ),
      ),
    );
  }
}
