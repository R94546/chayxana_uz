import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dish_model.dart';
import '../../models/order_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/push_notification_service.dart';

/// Admin ekrani - mijoz uchun taom buyurtma qo'shish
class AdminAddOrderScreen extends StatefulWidget {
  final String bookingId;
  final String choyxonaId;
  final String userId;
  final String? roomNumber;

  const AdminAddOrderScreen({
    super.key,
    required this.bookingId,
    required this.choyxonaId,
    required this.userId,
    this.roomNumber,
  });

  @override
  State<AdminAddOrderScreen> createState() => _AdminAddOrderScreenState();
}

class _AdminAddOrderScreenState extends State<AdminAddOrderScreen> {
  List<DishModel> _dishes = [];
  final Map<String, OrderItemData> _cart = {}; // dishId -> data
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _selectedCategory = 'all';
  TimeOfDay _deliveryTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  Future<void> _loadDishes() async {
    try {
      debugPrint('🍽️ Loading dishes for choyxonaId: ${widget.choyxonaId}');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('menu_items')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .get();

      debugPrint('🍽️ Found ${snapshot.docs.length} dishes');
      
      setState(() {
        _dishes = snapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList();
        _isLoading = false;
      });
      
      if (_dishes.isEmpty) {
        debugPrint('⚠️ No dishes found! Check if dishes exist in Firestore with choyxonaId: ${widget.choyxonaId}');
      }
    } catch (e) {
      debugPrint('❌ Error loading dishes: $e');
      setState(() => _isLoading = false);
    }
  }

  double get _totalAmount {
    return _cart.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['all', ..._dishes.map((d) => d.category).toSet().toList()];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Taom qo\'shish${widget.roomNumber != null ? ' (Xona ${widget.roomNumber})' : ''}'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Kategoriyalar
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat == 'all' ? 'Hammasi' : cat),
                          selected: isSelected,
                          onSelected: (v) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    },
                  ),
                ),

                // Taomlar ro'yxati
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredDishes.length,
                    itemBuilder: (context, index) {
                      final dish = _filteredDishes[index];
                      return _buildDishCard(dish);
                    },
                  ),
                ),

                // Cart summary
                if (_cart.isNotEmpty) _buildCartSummary(),
              ],
            ),
    );
  }

  List<DishModel> get _filteredDishes {
    if (_selectedCategory == 'all') return _dishes;
    return _dishes.where((d) => d.category == _selectedCategory).toList();
  }

  Widget _buildDishCard(DishModel dish) {
    final cartItem = _cart[dish.id];
    final unit = dish.unit;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rasm
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
                  ? Image.network(dish.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                  : Container(
                      width: 60,
                      height: 60,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.restaurant, color: AppColors.primary),
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dish.name, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrice(dish.price)} / $unit',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            // Controls
            if (cartItem == null)
              IconButton(
                onPressed: () => _addToCart(dish),
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
              )
            else
              Row(
                children: [
                  IconButton(
                    onPressed: () => _updateQuantity(dish.id, -0.5),
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                  ),
                  Text('${cartItem.quantity} $unit', style: AppTextStyles.bodyMedium),
                  IconButton(
                    onPressed: () => _updateQuantity(dish.id, 0.5),
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Keltirish vaqti
          Row(
            children: [
              const Icon(Icons.access_time, size: 20),
              const SizedBox(width: 8),
              const Text('Keltirish vaqti:'),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _deliveryTime,
                  );
                  if (time != null) setState(() => _deliveryTime = time);
                },
                child: Text('${_deliveryTime.hour.toString().padLeft(2, '0')}:${_deliveryTime.minute.toString().padLeft(2, '0')}'),
              ),
            ],
          ),
          const Divider(),
          // Jami
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jami: ${_cart.length} ta taom', style: AppTextStyles.bodyMedium),
              Text(_formatPrice(_totalAmount), style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          // Tugma
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOrder,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Buyurtmani qo\'shish'),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(DishModel dish) {
    setState(() {
      _cart[dish.id] = OrderItemData(
        dishId: dish.id,
        dishName: dish.name,
        price: dish.price,
        quantity: 1,
        unit: dish.unit,
      );
    });
  }

  void _updateQuantity(String dishId, double delta) {
    setState(() {
      final item = _cart[dishId];
      if (item != null) {
        final newQty = item.quantity + delta;
        if (newQty <= 0) {
          _cart.remove(dishId);
        } else {
          _cart[dishId] = OrderItemData(
            dishId: item.dishId,
            dishName: item.dishName,
            price: item.price,
            quantity: newQty,
            unit: item.unit,
          );
        }
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final deliveryTimeStr = '${_deliveryTime.hour.toString().padLeft(2, '0')}:${_deliveryTime.minute.toString().padLeft(2, '0')}';

      // OrderModel yaratish
      final items = _cart.values.map((item) => OrderItem(
        dishId: item.dishId,
        dishName: item.dishName,
        price: item.price,
        quantity: item.quantity,
        unit: item.unit,
        deliveryTime: deliveryTimeStr,
      )).toList();

      final orderData = {
        'choyxonaId': widget.choyxonaId,
        'bookingId': widget.bookingId,
        'userId': widget.userId,
        'items': items.map((i) => i.toMap()).toList(),
        'status': 'new',
        'subtotal': _totalAmount,
        'discount': 0,
        'tips': 0,
        'total': _totalAmount,
        'addedBy': 'admin',
        'adminNote': 'Xona ${widget.roomNumber ?? '-'}',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);

      // Booking'ga hasOrder = true qo'shish
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'hasOrder': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mijozga notification
      await PushNotificationService().sendNotificationToUser(
        userId: widget.userId,
        title: 'Taom buyurtmasi qo\'shildi! 🍽️',
        body: 'Admin sizga ${_cart.length} ta taom qo\'shdi. Jami: ${_formatPrice(_totalAmount)}',
        data: {
          'type': 'order_added',
          'bookingId': widget.bookingId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buyurtma qo\'shildi'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xato: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)} so\'m';
  }
}

class OrderItemData {
  final String dishId;
  final String dishName;
  final double price;
  final double quantity;
  final String unit;

  OrderItemData({
    required this.dishId,
    required this.dishName,
    required this.price,
    required this.quantity,
    required this.unit,
  });
}
