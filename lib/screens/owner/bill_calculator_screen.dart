import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран калькулятора счёта
class BillCalculatorScreen extends StatefulWidget {
  final OrderModel order;

  const BillCalculatorScreen({
    super.key,
    required this.order,
  });

  @override
  State<BillCalculatorScreen> createState() => _BillCalculatorScreenState();
}

class _BillCalculatorScreenState extends State<BillCalculatorScreen> {
  double _discount = 0;
  double _tips = 0;
  int _splitCount = 1;
  bool _isLoading = false;

  double get _discountAmount => widget.order.subtotal * (_discount / 100);
  double get _totalAfterDiscount => widget.order.subtotal - _discountAmount;
  double get _grandTotal => _totalAfterDiscount + _tips;
  double get _perPerson => _grandTotal / _splitCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Счёт для стола ${widget.order.tableNumber}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Детали заказа
            _buildOrderDetails(),

            const SizedBox(height: 24),

            // Скидка
            _buildDiscountSection(),

            const SizedBox(height: 24),

            // Чаевые
            _buildTipsSection(),

            const SizedBox(height: 24),

            // Разделить счёт
            _buildSplitSection(),

            const SizedBox(height: 24),

            // Итоговая сумма
            _buildTotalSection(),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildPayButton(),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Заказ',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 12),
          ...widget.order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.dishName} x${item.quantity}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  Text(
                    '${item.total.toStringAsFixed(0)} сум',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Промежуточная сумма:',
                style: AppTextStyles.titleMedium,
              ),
              Text(
                '${widget.order.subtotal.toStringAsFixed(0)} сум',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Скидка',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _discount,
                  min: 0,
                  max: 50,
                  divisions: 10,
                  label: '${_discount.toInt()}%',
                  onChanged: (value) {
                    setState(() {
                      _discount = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_discount.toInt()}%',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Сумма скидки:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '- ${_discountAmount.toStringAsFixed(0)} сум',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Чаевые',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTipsButton('5%', _totalAfterDiscount * 0.05),
              _buildTipsButton('10%', _totalAfterDiscount * 0.10),
              _buildTipsButton('15%', _totalAfterDiscount * 0.15),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Или введите сумму',
              suffixText: 'сум',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _tips = double.tryParse(value) ?? 0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTipsButton(String label, double amount) {
    final isSelected = (_tips - amount).abs() < 1;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tips = amount;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${amount.toStringAsFixed(0)} сум',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Разделить счёт',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 32),
                color: AppColors.error,
                onPressed: _splitCount > 1
                    ? () {
                  setState(() {
                    _splitCount--;
                  });
                }
                    : null,
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Text(
                    _splitCount.toString(),
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _splitCount == 1 ? 'человек' : 'человек(а)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 32),
                color: AppColors.success,
                onPressed: _splitCount < 20
                    ? () {
                  setState(() {
                    _splitCount++;
                  });
                }
                    : null,
              ),
            ],
          ),
          if (_splitCount > 1) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'С каждого: ${_perPerson.toStringAsFixed(0)} сум',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Промежуточная:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textWhite.withOpacity(0.9),
                ),
              ),
              Text(
                '${widget.order.subtotal.toStringAsFixed(0)} сум',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textWhite.withOpacity(0.9),
                ),
              ),
            ],
          ),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Скидка ($_discount%):',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite.withOpacity(0.9),
                  ),
                ),
                Text(
                  '- ${_discountAmount.toStringAsFixed(0)} сум',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
          if (_tips > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Чаевые:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite.withOpacity(0.9),
                  ),
                ),
                Text(
                  '+ ${_tips.toStringAsFixed(0)} сум',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textWhite.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 24, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ИТОГО:',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textWhite,
                ),
              ),
              Text(
                '${_grandTotal.toStringAsFixed(0)} сум',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
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
        child: ElevatedButton(
          onPressed: _isLoading ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          child: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.textWhite,
              strokeWidth: 2,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.payment, size: 24),
              const SizedBox(width: 8),
              Text(
                'Оплатить ${_grandTotal.toStringAsFixed(0)} сум',
                style: AppTextStyles.button,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      // Обновляем заказ
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
        'status': 'paid',
        'discount': _discount,
        'tips': _tips,
        'total': _grandTotal,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Освобождаем стол
      await FirebaseFirestore.instance
          .collection('tables')
          .doc(widget.order.tableId)
          .update({
        'status': 'free',
        'currentOrderId': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Оплата успешно проведена! 💰'),
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