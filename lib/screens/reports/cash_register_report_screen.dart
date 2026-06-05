import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/order_model.dart';
import '../../widgets/ethereal_components.dart';
import '../../widgets/receipt_dialog.dart';

/// 💰 Kassa Eshigi (Cash Register) - Operativ ish stoli
class CashRegisterReportScreen extends StatefulWidget {
  final String choyxonaId;
  final String choyxonaName;
  final bool embedded;
  
  const CashRegisterReportScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaName,
    this.embedded = false,
  });

  @override
  State<CashRegisterReportScreen> createState() => _CashRegisterReportScreenState();
}

class _CashRegisterReportScreenState extends State<CashRegisterReportScreen> {
  // Tanlangan bron va uning zakazlari
  Map<String, dynamic>? _selectedBooking;
  List<OrderModel> _bookingOrders = [];
  bool _isLoadingOrders = false;
  
  // Bugungi sana queries uchun
  late DateTime _startOfDay;
  late DateTime _endOfDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startOfDay = DateTime(now.year, now.month, now.day);
    _endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  // Bron tanlanganda orderlarni yuklash
  Future<void> _selectBooking(Map<String, dynamic> booking, String bookingId) async {
    setState(() {
      _selectedBooking = {...booking, 'id': bookingId};
      _isLoadingOrders = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('bookingId', isEqualTo: bookingId)
          .get();

      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _bookingOrders = orders;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        // Chap tomon: Bugungi bronlar
        Expanded(
          flex: 4,
          child: _buildBookingsList(),
        ),
        // O'ng tomon: Order detallari
        Expanded(
          flex: 6,
          child: _buildOrderDetails(),
        ),
      ],
    );

    if (widget.embedded) {
      return Container(
        color: AppColors.background,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kassa', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: content,
    );
  }

  Widget _buildBookingsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Bugungi Bronlar',
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('choyxonaId', isEqualTo: widget.choyxonaId)
                  .where('date', isEqualTo: DateFormat('dd.MM.yyyy').format(_startOfDay))
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Xatolik: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bookings = snapshot.data!.docs;
                
                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Bugun bronlar yo\'q', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: bookings.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final booking = bookings[index].data() as Map<String, dynamic>;
                    final bookingId = bookings[index].id;
                    final isSelected = _selectedBooking?['id'] == bookingId;
                    
                    final status = booking['status'] ?? 'pending';
                    Color statusColor = Colors.grey;
                    if (status == 'confirmed') statusColor = Colors.blue;
                    else if (status == 'completed') statusColor = Colors.green;
                    else if (status == 'cancelled') statusColor = Colors.red;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withOpacity(0.1),
                      onTap: () => _selectBooking(booking, bookingId),
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Text(
                          (booking['guestName'] ?? 'M')[0].toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        booking['guestName'] ?? 'Noma\'lum',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(booking['time'] ?? '--:--'),
                          const SizedBox(width: 12),
                          Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('${booking['guests'] ?? 0}'),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    if (_selectedBooking == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Tafsilotlarni ko\'rish uchun bronni tanlang',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    // Agar orderlar bo'lmasa
    if (_bookingOrders.isEmpty) {
      return _buildEmptyOrderView();
    }

    // Asosiy order (oxirgisi yoki birinchisi - soddalik uchun barchasini ko'rsatamiz)
    // Lekin odatda bitta active order bo'ladi. Keling barchasini scroll qilib ko'rsatamiz.
    
    double grandTotal = _bookingOrders.fold(0, (sum, order) => sum + order.totalAmount);

    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         _selectedBooking!['roomName'] ?? _selectedBooking!['tableName'] ?? 'Stol #',
                         style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                       ),
                       Text(
                         'Mijoz: ${_selectedBooking!['guestName']}',
                         style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
                       ),
                     ],
                   ),
                 ),
                 Text(
                   NumberFormat.currency(locale: 'uz', symbol: "so'm", decimalDigits: 0).format(grandTotal),
                   style: AppTextStyles.headlineSmall.copyWith(
                     color: AppColors.primary,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookingOrders.length,
              itemBuilder: (context, index) {
                final order = _bookingOrders[index];
                return _buildOrderCard(order);
              },
            ),
          ),
          
          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                // Print Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceiptDialog(_bookingOrders.last), // Simple: print last order
                    icon: const Icon(Icons.print),
                    label: const Text('Chek Chiqarish'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Complete Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _bookingOrders.any((o) => o.status != 'paid') 
                        ? () => _completeAllOrders()
                        : null, // Disable if all paid
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Zakazni Yopish (To\'landi)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderId.substring(0,6).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const Divider(height: 24),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.quantityDisplay} x ${item.dishName}'),
                  Text(
                    NumberFormat.currency(locale: 'uz', symbol: "", decimalDigits: 0).format(item.total),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrderView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Bu bronda hali zakaz yo\'q',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          // Bu yerda "Zakaz qo'shish" tugmasi bo'lishi mumkin, lekin u boshqa ekranga olib o'tadi
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String text = status;
    
    if (status == 'paid') {
      color = AppColors.success;
      text = 'To\'langan';
    } else if (status == 'new') {
      color = Colors.orange;
      text = 'Yangi';
    } else if (status == 'served') {
      color = Colors.blue;
      text = 'Xizmat ko\'rsatildi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  void _showReceiptDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => ReceiptDialog(
        order: order,
        choyxonaName: widget.choyxonaName,
        tableName: _selectedBooking?['roomName'] ?? _selectedBooking?['tableName'],
      ),
    );
  }

  Future<void> _completeAllOrders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tasdiqlash'),
        content: const Text('Barcha zakazlarni to\'langan deb belgilab, bronni yakunlaysizmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Yo\'q')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ha')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingOrders = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Update orders
      for (var order in _bookingOrders) {
        if (order.status != 'paid') {
          final ref = FirebaseFirestore.instance.collection('orders').doc(order.id);
          batch.update(ref, {'status': 'paid', 'paidAt': FieldValue.serverTimestamp()});
        }
      }

      // Update booking
      if (_selectedBooking != null) {
        final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(_selectedBooking!['id']);
        batch.update(bookingRef, {'status': 'completed'});
      }

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Muvaffaqiyatli yakunlandi'), backgroundColor: Colors.green),
        );
        // Refresh orders
        _selectBooking(_selectedBooking!, _selectedBooking!['id']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }
}
