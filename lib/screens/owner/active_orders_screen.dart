import 'package:flutter/material.dart';
import '../../models/order_model.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Экран активных заказов
class ActiveOrdersScreen extends StatefulWidget {
  final String choyxonaId;

  const ActiveOrdersScreen({
    super.key,
    required this.choyxonaId,
  });

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen>
    with SingleTickerProviderStateMixin {
  String _selectedStatus = 'all';
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_blinkController);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Активные заказы'),
      ),
      body: Column(
        children: [
          _buildStatusFilters(),
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  /// Фильтры по статусу
  Widget _buildStatusFilters() {
    final statuses = [
      {'id': 'all', 'name': 'Все', 'color': Colors.grey},
      {'id': 'new', 'name': 'Новые', 'color': Colors.orange},
      {'id': 'preparing', 'name': 'Готовятся', 'color': Colors.blue},
      {'id': 'ready', 'name': 'Готовы', 'color': Colors.green},
      {'id': 'served', 'name': 'Поданы', 'color': Colors.grey},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status['name'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = status['id'] as String;
                });
              },
              selectedColor: status['color'] as Color,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Список заказов
  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки заказов',
                  style: AppTextStyles.titleLarge,
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = OrderModel.fromFirestore(orders[index]);
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  /// Stream заказов
  Stream<QuerySnapshot> _getOrdersStream() {
    var query = FirebaseFirestore.instance
        .collection('orders')
        .where('choyxonaId', isEqualTo: widget.choyxonaId)
        .where('status', whereIn: ['new', 'preparing', 'ready', 'served']);

    if (_selectedStatus != 'all') {
      query = FirebaseFirestore.instance
          .collection('orders')
          .where('choyxonaId', isEqualTo: widget.choyxonaId)
          .where('status', isEqualTo: _selectedStatus);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  /// Пустое состояние
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет активных заказов',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Заказы появятся здесь',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Карточка заказа
  Widget _buildOrderCard(OrderModel order) {
    // Check if order delivery time is due
    final isDue = _isOrderDue(order);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          // Blinking indicator for due orders
          if (isDue)
            Positioned(
              top: 8,
              left: 8,
              child: AnimatedBuilder(
                animation: _blinkAnimation,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(_blinkAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(_blinkAnimation.value * 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: EdgeInsets.all(isDue ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.table_bar,
                          color: isDue ? Colors.green : AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Стол ${order.tableNumber}',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: isDue ? Colors.green : null,
                          ),
                        ),
                        if (isDue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'VAQTI KELDI!',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    _buildStatusBadge(order.status),
              ],
            ),

            const SizedBox(height: 12),

            // Список блюд
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.dishName} × ${item.quantity}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Text(
                      '${(item.price * item.quantity).toStringAsFixed(0)} сум',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const Divider(height: 24),

            // Итого и кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Итого:',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${order.totalAmount.toStringAsFixed(0)} сум',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                _buildStatusButtons(order),
              ],
            ),

            // Время создания
            const SizedBox(height: 8),
            Text(
              'Создан: ${_formatTime(order.createdAt)}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Бейдж статуса
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'new':
        color = Colors.orange;
        text = 'Новый';
        break;
      case 'preparing':
        color = Colors.blue;
        text = 'Готовится';
        break;
      case 'ready':
        color = Colors.green;
        text = 'Готов';
        break;
      case 'served':
        color = Colors.grey;
        text = 'Подан';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Кнопки смены статуса
  Widget _buildStatusButtons(OrderModel order) {
    String? nextStatus;
    String? buttonText;

    switch (order.status) {
      case 'new':
        nextStatus = 'preparing';
        buttonText = 'Готовится';
        break;
      case 'preparing':
        nextStatus = 'ready';
        buttonText = 'Готов';
        break;
      case 'ready':
        nextStatus = 'served';
        buttonText = 'Подан';
        break;
      default:
        return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: () => _updateOrderStatus(order.orderId, nextStatus!),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(buttonText),
    );
  }

  /// Обновить статус заказа
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Статус обновлён'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Форматировать время
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
  
  /// Check if order delivery time is due
  bool _isOrderDue(OrderModel order) {
    // Parse delivery time from notes: "Keltirish vaqti: 16:25"
    final notes = order.notes ?? '';
    final regex = RegExp(r'(\d{1,2}):(\d{2})');
    final match = regex.firstMatch(notes);
    
    if (match == null) return false;
    
    final hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    
    final now = DateTime.now();
    final deliveryTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    // Order is due if current time >= delivery time (within today)
    return now.isAfter(deliveryTime) || now.isAtSameMomentAs(deliveryTime);
  }
}

