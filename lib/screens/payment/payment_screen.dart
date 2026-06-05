import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран оплаты бронирования
class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final String choyxonaName;
  final double amount;
  final String currency;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.choyxonaName,
    required this.amount,
    this.currency = 'UZS',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'card';
  bool _isProcessing = false;
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'card', 'name': 'Банковская карта', 'icon': Icons.credit_card},
    {'id': 'payme', 'name': 'Payme', 'icon': Icons.payment},
    {'id': 'click', 'name': 'Click', 'icon': Icons.touch_app},
    {'id': 'cash', 'name': 'Наличными', 'icon': Icons.money},
  ];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('payment'.tr()),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о бронировании
            _buildBookingInfo(isDark),
            const SizedBox(height: 24),

            // Способы оплаты
            Text(
              'payment_method'.tr(),
              style: AppTextStyles.titleMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethods(isDark),
            const SizedBox(height: 24),

            // Форма оплаты (если карта)
            if (_selectedMethod == 'card') ...[
              _buildCardForm(isDark),
              const SizedBox(height: 24),
            ],

            // Внешние платёжные системы
            if (_selectedMethod == 'payme' || _selectedMethod == 'click') ...[
              _buildExternalPaymentInfo(isDark),
              const SizedBox(height: 24),
            ],

            // Оплата наличными
            if (_selectedMethod == 'cash') ...[
              _buildCashInfo(isDark),
              const SizedBox(height: 24),
            ],

            // Кнопка оплаты
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _selectedMethod == 'cash'
                            ? 'confirm_booking'.tr()
                            : '${'pay'.tr()} ${_formatAmount(widget.amount)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Безопасность
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'secure_payment'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.choyxonaName,
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'total'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
              Text(
                _formatAmount(widget.amount),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _paymentMethods.map((method) {
        final isSelected = _selectedMethod == method['id'];
        return InkWell(
          onTap: () => setState(() => _selectedMethod = method['id']),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : (isDark ? AppColors.darkSurface : AppColors.surface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : (isDark ? AppColors.darkBorder : AppColors.border),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  method['icon'],
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  method['name'],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: 'card_number'.tr(),
              hintText: '0000 0000 0000 0000',
              prefixIcon: const Icon(Icons.credit_card),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            maxLength: 19,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,
                  decoration: InputDecoration(
                    labelText: 'expiry_date'.tr(),
                    hintText: 'MM/YY',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '***',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cardHolderController,
            decoration: InputDecoration(
              labelText: 'card_holder'.tr(),
              hintText: 'IVAN IVANOV',
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
    );
  }

  Widget _buildExternalPaymentInfo(bool isDark) {
    final name = _selectedMethod == 'payme' ? 'Payme' : 'Click';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.open_in_new,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Вы будете перенаправлены на $name',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Оплата через защищённое соединение',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 32, color: AppColors.success),
          const SizedBox(height: 12),
          Text(
            'Оплата наличными',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: 8),
          Text(
            'Оплатите заказ наличными по прибытии в чайхану',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
    return '$formatted ${widget.currency}';
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Симуляция обработки платежа
      await Future.delayed(const Duration(seconds: 2));

      // Обновляем статус бронирования
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'paymentStatus': _selectedMethod == 'cash' ? 'pending' : 'paid',
        'paymentMethod': _selectedMethod,
        'paidAt': _selectedMethod != 'cash' ? FieldValue.serverTimestamp() : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedMethod == 'cash'
                  ? 'Бронирование подтверждено'
                  : 'Оплата прошла успешно!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
