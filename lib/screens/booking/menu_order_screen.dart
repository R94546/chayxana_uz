import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dish_model.dart';
import '../../models/order_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';

/// Экран заказа еды (после подтверждения брони)
class MenuOrderScreen extends StatefulWidget {
  final String bookingId;
  final String choyxonaId;
  final String choyxonaName;

  const MenuOrderScreen({
    super.key,
    required this.bookingId,
    required this.choyxonaId,
    required this.choyxonaName,
  });

  @override
  State<MenuOrderScreen> createState() => _MenuOrderScreenState();
}

class _MenuOrderScreenState extends State<MenuOrderScreen> {
  List<DishModel> _dishes = [];
  bool _isLoading = true;
  
  // Корзина: dishId -> {quantity, deliveryTime}
  Map<String, OrderItemData> _cart = {};
  
  // Выбранное время доставки
  String _globalDeliveryTime = '12:00';
  
  final List<String> _deliveryTimes = [
    '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00', '20:30', '21:00', '21:30', '22:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadDishes();
  }

  Future<void> _loadDishes() async {
    try {
      debugPrint('Loading dishes for choyxonaId: ${widget.choyxonaId}');
      final snapshot = await FirebaseFirestore.instance
          .collection('menu_items')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .get();

      debugPrint('Found ${snapshot.docs.length} dishes');
      for (var doc in snapshot.docs) {
        debugPrint('Dish: ${doc.data()['name']} - choyxonaId: ${doc.data()['choyxonaId']}');
      }

      if (mounted) {
        setState(() {
          _dishes = snapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dishes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _totalAmount {
    double total = 0;
    for (var entry in _cart.entries) {
      final dish = _dishes.firstWhere((d) => d.id == entry.key, orElse: () => _dishes.first);
      total += dish.price * entry.value.quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Taom buyurtma qilish'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Заголовок чайханы
                _buildHeader(),
                
                // Выбор времени доставки
                _buildDeliveryTimeSelector(),

                // Список блюд
                Expanded(
                  child: _dishes.isEmpty
                      ? _buildEmptyState()
                      : _buildDishList(),
                ),

                // Корзина
                if (_cart.isNotEmpty) _buildCartSummary(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.choyxonaName, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Taom tanlang va keltirish vaqtini belgilang',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: AppColors.primary),
          const SizedBox(width: 12),
          Text('Keltirish vaqti:', style: AppTextStyles.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: _globalDeliveryTime,
              isExpanded: true,
              underline: const SizedBox(),
              items: _deliveryTimes.map((time) {
                return DropdownMenuItem(
                  value: time,
                  child: Text(time, style: AppTextStyles.titleSmall),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _globalDeliveryTime = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text('Menyu hali to\'ldirilmagan', style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildDishList() {
    // Группируем по категориям
    final categories = <String, List<DishModel>>{};
    for (var dish in _dishes) {
      final category = dish.category ?? 'Boshqa';
      categories.putIfAbsent(category, () => []).add(dish);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final dishes = categories[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(category, style: AppTextStyles.titleMedium),
            ),
            ...dishes.map((dish) => _buildDishCard(dish)),
          ],
        );
      },
    );
  }

  Widget _buildDishCard(DishModel dish) {
    final cartItem = _cart[dish.id];
    final isInCart = cartItem != null && cartItem.quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInCart ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInCart ? AppColors.success : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фото блюда
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: dish.imageUrl.isNotEmpty
                ? Image.network(
                    dish.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 12),
          
          // Информация о блюде
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dish.name, style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '${_formatPrice(dish.price)} / ${dish.unit}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (dish.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dish.description,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Количество
          Column(
            children: [
              if (isInCart) ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.error,
                      onPressed: () => _updateQuantity(dish, -0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${cartItem.quantity} ${dish.unit}',
                        style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.success,
                      onPressed: () => _updateQuantity(dish, 0.5),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () => _addToCart(dish),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Qo\'shish'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.restaurant, color: AppColors.textLight),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Список заказанного
            ...(_cart.entries.map((entry) {
              final dish = _dishes.firstWhere((d) => d.id == entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${dish.name} x ${entry.value.quantity} ${dish.unit}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Text(
                      _formatPrice(dish.price * entry.value.quantity),
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            })),
            
            const Divider(),
            
            // Итого
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jami:', style: AppTextStyles.titleMedium),
                Text(
                  _formatPrice(_totalAmount),
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Кнопка заказа
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Buyurtmani tasdiqlash ($_globalDeliveryTime)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(DishModel dish) {
    setState(() {
      _cart[dish.id] = OrderItemData(
        quantity: dish.unit == 'kg' ? 1.0 : 1.0,
        deliveryTime: _globalDeliveryTime,
      );
    });
  }

  void _updateQuantity(DishModel dish, double delta) {
    setState(() {
      final current = _cart[dish.id];
      if (current != null) {
        final newQty = current.quantity + delta;
        if (newQty <= 0) {
          _cart.remove(dish.id);
        } else {
          _cart[dish.id] = OrderItemData(
            quantity: newQty,
            deliveryTime: _globalDeliveryTime,
          );
        }
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUserData();

      if (currentUser == null) {
        _showError('Avtorizatsiya talab qilinadi');
        setState(() => _isLoading = false);
        return;
      }

      // Формируем элементы заказа
      final items = _cart.entries.map((entry) {
        final dish = _dishes.firstWhere((d) => d.id == entry.key);
        return {
          'dishId': dish.id,
          'dishName': dish.name,
          'price': dish.price,
          'quantity': entry.value.quantity,
          'unit': dish.unit,
          'deliveryTime': _globalDeliveryTime,
          'notes': null,
        };
      }).toList();

      // Создаём заказ
      final orderData = {
        'choyxonaId': widget.choyxonaId,
        'bookingId': widget.bookingId,
        'userId': currentUser.userId,
        'items': items,
        'status': 'new',
        'subtotal': _totalAmount,
        'discount': 0,
        'tips': 0,
        'total': _totalAmount,
        'addedBy': 'client',
        'adminNote': null,
        'notes': 'Keltirish vaqti: $_globalDeliveryTime',
        'isRated': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);

      // Обновляем бронирование
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({'hasOrder': true});

      // Notify admin in background (fire and forget)
      final userName = currentUser.fullName.isNotEmpty ? currentUser.fullName : 'Mijoz';
      _notifyAdmin(userName);

      if (mounted) {
        _showSuccess('Buyurtma qabul qilindi! 🎉');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError('Xatolik yuz berdi');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _notifyAdmin(String userName) async {
    try {
      final adminsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .where('role', whereIn: ['choyxona_admin', 'choyxona_owner'])
          .get();

      for (var adminDoc in adminsSnapshot.docs) {
        await PushNotificationService().sendNotificationToUser(
          userId: adminDoc.id,
          title: 'Yangi taom buyurtmasi! 🍽️',
          body: '$userName ${_formatPrice(_totalAmount)} miqdorda buyurtma berdi ($_globalDeliveryTime ga)',
          data: {
            'type': 'new_order',
            'bookingId': widget.bookingId,
          },
        );
      }
    } catch (e) {
      debugPrint('Error notifying admin: $e');
    }
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)} so\'m';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }
}

/// Данные элемента корзины
class OrderItemData {
  final double quantity;
  final String deliveryTime;

  OrderItemData({required this.quantity, required this.deliveryTime});
}
