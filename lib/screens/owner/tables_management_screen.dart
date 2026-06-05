import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/table_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'create_order_screen.dart';

class TablesManagementScreen extends StatefulWidget {
  final String choyxonaId;

  const TablesManagementScreen({
    super.key,
    required this.choyxonaId,
  });

  @override
  State<TablesManagementScreen> createState() => _TablesManagementScreenState();
}

class _TablesManagementScreenState extends State<TablesManagementScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Xonalarni boshqarish'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTableDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры по статусу
          _buildStatusFilters(),

          // Карта зала
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tables')
                  .where('choyxonaId', isEqualTo: widget.choyxonaId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Получаем все столы
                var allTables = snapshot.data!.docs
                    .map((doc) => TableModel.fromFirestore(doc))
                    .toList();

                // Проверяем бронирования и обновляем статус столов
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('choyxonaId', isEqualTo: widget.choyxonaId)
                      .where('status', isEqualTo: 'confirmed')
                      .snapshots(),
                  builder: (context, bookingSnapshot) {
                    // Обновляем статусы столов на основе бронирований
                    if (bookingSnapshot.hasData) {
                      final today = DateTime.now();
                      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

                      for (var bookingDoc in bookingSnapshot.data!.docs) {
                        final bookingData = bookingDoc.data() as Map<String, dynamic>;
                        final bookingDate = bookingData['bookingDate'] as String?;
                        final tableNumber = bookingData['tableNumber'] as String?;

                        // Если бронирование на сегодня - меняем статус стола
                        if (bookingDate == todayStr && tableNumber != null) {
                          final tableIndex = allTables.indexWhere((t) => t.number == tableNumber);
                          if (tableIndex != -1 && allTables[tableIndex].status == 'free') {
                            allTables[tableIndex] = allTables[tableIndex].copyWith(
                              status: 'reserved',
                              currentBookingId: bookingDoc.id,
                            );
                          }
                        }
                      }
                    }

                    // Применяем фильтр
                    final tables = allTables.where((table) {
                      if (_filterStatus == 'all') return true;
                      return table.status == _filterStatus;
                    }).toList();

                    if (tables.isEmpty) {
                      return _buildEmptyState(
                        message: 'Bu statusda xonalar yo\'q',
                      );
                    }

                    return _buildFloorPlan(tables);
                  },
                );
              },
            ),
          ),

          // Легенда
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('Все', 'all', Icons.table_bar),
          _buildFilterChip('Свободно', 'free', Icons.check_circle),
          _buildFilterChip('Занято', 'occupied', Icons.restaurant),
          _buildFilterChip('Забронировано', 'reserved', Icons.event),
          _buildFilterChip('Недоступно', 'unavailable', Icons.block),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status, IconData icon) {
    final isActive = _filterStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = status;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.textWhite : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isActive ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorPlan(List<TableModel> tables) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: DragTarget<TableModel>(
        onAccept: (draggedTable) {
          print('Стол ${draggedTable.number} перемещён');
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: tables.map((table) {
                return Positioned(
                  left: table.positionX,
                  top: table.positionY,
                  child: _TableWidget(
                    table: table,
                    onTap: () => _showTableMenu(table),
                    onDragEnd: (offset) => _updateTablePosition(table, offset),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('Свободно', AppColors.success),
            _buildLegendItem('Занято', AppColors.error),
            _buildLegendItem('Забронировано', AppColors.warning),
            _buildLegendItem('Недоступно', AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall,
        ),
      ],
    );
  }

  Widget _buildEmptyState({String message = 'Xonalar yo\'q'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_bar,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTableDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Xona qo\'shish'),
          ),
        ],
      ),
    );
  }

  void _showTableMenu(TableModel table) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _TableMenuSheet(
        table: table,
        onCreateOrder: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateOrderScreen(
                choyxonaId: widget.choyxonaId,
                table: table,
              ),
            ),
          );
        },
        onChangeStatus: (status) {
          _updateTableStatus(table.id, status);
          Navigator.pop(context);
        },
        onEdit: () {
          Navigator.pop(context);
          _showEditTableDialog(table);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteTable(table.id);
        },
      ),
    );
  }

  void _showAddTableDialog() {
    final numberController = TextEditingController();
    final capacityController = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xona qo\'shish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Xona raqami',
                hintText: '1, A1, VIP-1...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(
                labelText: 'Вместимость (мест)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (numberController.text.isEmpty) return;

              final table = TableModel(
                id: '',
                choyxonaId: widget.choyxonaId,
                number: numberController.text,
                capacity: int.tryParse(capacityController.text) ?? 4,
                status: 'free',
                positionX: 50 + (DateTime.now().millisecond % 200).toDouble(),
                positionY: 50 + (DateTime.now().second % 200).toDouble(),
              );

              await FirebaseFirestore.instance
                  .collection('tables')
                  .add(table.toMap());

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xona qo\'shildi'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showEditTableDialog(TableModel table) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Редактирование в разработке')),
    );
  }

  Future<void> _updateTableStatus(String tableId, String status) async {
    await FirebaseFirestore.instance.collection('tables').doc(tableId).update({
      'status': status,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Статус обновлён'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _updateTablePosition(TableModel table, Offset offset) async {
    try {
      // Вычисляем новую позицию
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final newX = (offset.dx - 16).clamp(0.0, 400.0);
      final newY = (offset.dy - 200).clamp(0.0, 500.0);

      await FirebaseFirestore.instance
          .collection('tables')
          .doc(table.id)
          .update({
        'positionX': newX,
        'positionY': newY,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Стол ${table.number} перемещён'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error updating table position: $e');
    }
  }

  Future<void> _deleteTable(String tableId) async {
    await FirebaseFirestore.instance.collection('tables').doc(tableId).delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Стол удалён'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

/// Виджет стола на карте (с drag & drop)
class _TableWidget extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;
  final Function(Offset)? onDragEnd;

  const _TableWidget({
    required this.table,
    required this.onTap,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      switch (table.status) {
        case 'free':
          return AppColors.success;
        case 'occupied':
          return AppColors.error;
        case 'reserved':
          return AppColors.warning;
        default:
          return AppColors.textLight;
      }
    }

    final tableWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: getColor().withOpacity(0.2),
          border: Border.all(color: getColor(), width: 2),
          shape: table.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
          borderRadius:
          table.shape != 'circle' ? BorderRadius.circular(12) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.number,
              style: AppTextStyles.titleLarge.copyWith(
                color: getColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 14, color: getColor()),
                const SizedBox(width: 2),
                Text(
                  table.capacity.toString(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: getColor(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Делаем стол перетаскиваемым
    return Draggable<TableModel>(
      data: table,
      feedback: Opacity(
        opacity: 0.7,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: getColor(),
            shape: table.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: table.shape != 'circle' ? BorderRadius.circular(12) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              table.number,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: tableWidget,
      ),
      onDragEnd: (details) {
        if (onDragEnd != null) {
          onDragEnd!(details.offset);
        }
      },
      child: tableWidget,
    );
  }
}

/// Меню стола
class _TableMenuSheet extends StatelessWidget {
  final TableModel table;
  final VoidCallback onCreateOrder;
  final Function(String) onChangeStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TableMenuSheet({
    required this.table,
    required this.onCreateOrder,
    required this.onChangeStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Стол ${table.number}',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Вместимость: ${table.capacity} мест',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Создать заказ
          if (table.isAvailable || table.isReserved)
            ListTile(
              leading: const Icon(Icons.restaurant_menu, color: AppColors.primary),
              title: const Text('Создать заказ'),
              onTap: onCreateOrder,
            ),

          // Изменить статус
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.primary),
            title: const Text('Изменить статус'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Выберите статус'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _statusOption(context, 'Свободно', 'free'),
                      _statusOption(context, 'Занято', 'occupied'),
                      _statusOption(context, 'Забронировано', 'reserved'),
                      _statusOption(context, 'Недоступно', 'unavailable'),
                    ],
                  ),
                ),
              );
            },
          ),

          // Редактировать
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.textSecondary),
            title: const Text('Редактировать'),
            onTap: onEdit,
          ),

          // Удалить
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.error),
            title: const Text('Удалить стол'),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _statusOption(BuildContext context, String label, String status) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onChangeStatus(status);
      },
    );
  }
}