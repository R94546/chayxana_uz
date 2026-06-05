import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/table_model.dart';
import '../../models/order_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';

/// Простое блюдо (временная модель, пока нет полного меню)
class Dish {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? image;

  Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.image,
  });
}

/// Экран создания заказа
class CreateOrderScreen extends StatefulWidget {
  final String choyxonaId;
  final TableModel table;

  const CreateOrderScreen({
    super.key,
    required this.choyxonaId,
    required this.table,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final List<OrderItem> _orderItems = [];
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'all';
  bool _isLoading = false;

  // Временное меню (пока нет полного функционала меню)
  final List<Dish> _menu = [
    Dish(id: '1', name: 'Плов', price: 35000, category: 'main'),
    Dish(id: '2', name: 'Шашлык из баранины', price: 45000, category: 'main'),
    Dish(id: '3', name: 'Лагман', price: 30000, category: 'main'),
    Dish(id: '4', name: 'Манты', price: 25000, category: 'main'),
    Dish(id: '5', name: 'Самса', price: 8000, category: 'appetizers'),
    Dish(id: '6', name: 'Салат Ачичук', price: 15000, category: 'appetizers'),
    Dish(id: '7', name: 'Чай зелёный', price: 5000, category: 'drinks'),
    Dish(id: '8', name: 'Кока-кола', price: 10000, category: 'drinks'),
    Dish(id: '9', name: 'Компот', price: 8000, category: 'drinks'),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _orderItems.fold(0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Заказ для стола ${widget.table.number}'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Категории меню
          _buildCategories(),

          // Меню блюд
          Expanded(
            child: _buildMenu(),
          ),
        ],
      ),
      bottomNavigationBar: _buildOrderSummary(),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'id': 'all', 'name': 'Все', 'icon': Icons.restaurant_menu},
      {'id': 'main', 'name': 'Основные', 'icon': Icons.restaurant},
      {'id': 'appetizers', 'name': 'Закуски', 'icon': Icons.egg},
      {'id': 'drinks', 'name': 'Напитки', 'icon': Icons.local_cafe},
    ];

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['id'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['name'] as String,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
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

  Widget _buildMenu() {
    final filteredMenu = _menu.where((dish) {
      if (_selectedCategory == 'all') return true;
      return dish.category == _selectedCategory;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMenu.length,
      itemBuilder: (context, index) {
        final dish = filteredMenu[index];
        final orderItem = _orderItems.firstWhere(
              (item) => item.dishId == dish.id,
          orElse: () => OrderItem(
            dishId: '',
            dishName: '',
            price: 0,
            quantity: 0,
          ),
        );
        final quantity = orderItem.dishId.isNotEmpty ? orderItem.quantity : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              dish.name,
              style: AppTextStyles.titleMedium,
            ),
            subtitle: Text(
              '${dish.price.toStringAsFixed(0)} сум',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.accent,
              ),
            ),
            trailing: quantity > 0
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.error,
                  onPressed: () => _decreaseQuantity(dish),
                ),
                Text(
                  quantity.toString(),
                  style: AppTextStyles.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                  onPressed: () => _increaseQuantity(dish),
                ),
              ],
            )
                : IconButton(
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary,
              onPressed: () => _increaseQuantity(dish),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    if (_orderItems.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Сводка
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Блюд: ${_orderItems.length}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      'Сумма: ${_subtotal.toStringAsFixed(0)} сум',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Кнопка просмотра заказа
                    OutlinedButton(
                      onPressed: () => _showOrderPreview(),
                      child: const Text('Просмотр'),
                    ),
                    const SizedBox(width: 12),
                    // Кнопка создания заказа
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createOrder,
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textWhite,
                        ),
                      )
                          : const Text('Создать'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _increaseQuantity(Dish dish) {
    setState(() {
      final index = _orderItems.indexWhere((item) => item.dishId == dish.id);
      if (index >= 0) {
        _orderItems[index] = OrderItem(
          dishId: dish.id,
          dishName: dish.name,
          price: dish.price,
          quantity: _orderItems[index].quantity + 1,
        );
      } else {
        _orderItems.add(OrderItem(
          dishId: dish.id,
          dishName: dish.name,
          price: dish.price,
          quantity: 1,
        ));
      }
    });
  }

  void _decreaseQuantity(Dish dish) {
    setState(() {
      final index = _orderItems.indexWhere((item) => item.dishId == dish.id);
      if (index >= 0) {
        if (_orderItems[index].quantity > 1) {
          _orderItems[index] = OrderItem(
            dishId: dish.id,
            dishName: dish.name,
            price: dish.price,
            quantity: _orderItems[index].quantity - 1,
          );
        } else {
          _orderItems.removeAt(index);
        }
      }
    });
  }

  void _showOrderPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Предпросмотр заказа',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _orderItems.length,
                    itemBuilder: (context, index) {
                      final item = _orderItems[index];
                      return ListTile(
                        title: Text(item.dishName),
                        subtitle: Text('${item.price.toStringAsFixed(0)} сум'),
                        trailing: Text(
                          'x${item.quantity} = ${item.total.toStringAsFixed(0)} сум',
                          style: AppTextStyles.titleMedium,
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Итого:', style: AppTextStyles.titleLarge),
                    Text(
                      '${_subtotal.toStringAsFixed(0)} сум',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createOrder() async {
    if (_orderItems.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = await AuthService().getCurrentUserData();

      final order = OrderModel(
        id: '',
        choyxonaId: widget.choyxonaId,
        tableId: widget.table.id,
        tableNumber: widget.table.number,
        userId: currentUser?.userId ?? '',
        items: _orderItems,
        status: 'new',
        subtotal: _subtotal,
        discount: 0,
        tips: 0,
        total: _subtotal,
        addedBy: 'admin',
        notes: _notesController.text,
        createdAt: DateTime.now(),
      );

      // Сохраняем заказ
      final docRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(order.toMap());

      // Обновляем статус стола
      await FirebaseFirestore.instance
          .collection('tables')
          .doc(widget.table.id)
          .update({
        'status': 'occupied',
        'currentOrderId': docRef.id,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заказ создан! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}