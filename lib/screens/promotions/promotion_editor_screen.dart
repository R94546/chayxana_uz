import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/promotion_model.dart';
import '../../services/promotion_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 🎉 Редактор акций (для владельцев и админов)
class PromotionEditorScreen extends StatefulWidget {
  final String choyxonaId;
  final Promotion? promotion; // null = создание новой
  
  const PromotionEditorScreen({
    super.key,
    required this.choyxonaId,
    this.promotion,
  });

  @override
  State<PromotionEditorScreen> createState() => _PromotionEditorScreenState();
}

class _PromotionEditorScreenState extends State<PromotionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promotionService = PromotionService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountController;
  late TextEditingController _promoCodeController;
  
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEditing => widget.promotion != null;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _discountController = TextEditingController(text: p?.discountPercent.toString() ?? '');
    _promoCodeController = TextEditingController(text: p?.promoCode ?? '');
    _startDate = p?.startDate ?? DateTime.now();
    _endDate = p?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'edit_promotion'.tr() : 'new_promotion'.tr()),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBackgroundGradient(isDark),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Название
              _buildTextField(
                controller: _titleController,
                label: 'promotion_title'.tr(),
                hint: 'enter_promotion_title'.tr(),
                validator: (v) => v!.isEmpty ? 'required_field'.tr() : null,
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Описание
              _buildTextField(
                controller: _descriptionController,
                label: 'description'.tr(),
                hint: 'enter_description'.tr(),
                maxLines: 4,
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Скидка
              _buildTextField(
                controller: _discountController,
                label: 'discount_percent'.tr(),
                hint: '10',
                keyboardType: TextInputType.number,
                suffix: const Text('%'),
                validator: (v) {
                  if (v!.isEmpty) return 'required_field'.tr();
                  final num = int.tryParse(v);
                  if (num == null || num < 1 || num > 100) {
                    return 'invalid_discount'.tr();
                  }
                  return null;
                },
                isDark: isDark,
              ),
              
              const SizedBox(height: 16),
              
              // Промокод
              _buildTextField(
                controller: _promoCodeController,
                label: 'promo_code'.tr(),
                hint: 'SALE20',
                isDark: isDark,
              ),
              
              const SizedBox(height: 24),
              
              // Даты
              Text(
                'promotion_dates'.tr(),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'start_date'.tr(),
                      date: _startDate,
                      onPicked: (d) => setState(() => _startDate = d),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'end_date'.tr(),
                      date: _endDate,
                      onPicked: (d) => setState(() => _endDate = d),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Активна
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: Text(
                  'promotion_active'.tr(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                activeColor: AppColors.getPrimary(isDark),
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: 32),
              
              // Кнопка сохранения
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrimary(isDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditing ? 'save_changes'.tr() : 'create_promotion'.tr(),
                          style: AppTextStyles.button,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffix,
    String? Function(String?)? validator,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.getTextPrimary(isDark)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 16), child: suffix)
            : null,
        filled: true,
        fillColor: isDark ? AppColors.darkCardBg : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.border,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required Function(DateTime) onPicked,
    required bool isDark,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.getTextSecondary(isDark),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.getPrimary(isDark),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(date),
                  style: TextStyle(
                    color: AppColors.getTextPrimary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('end_date_error'.tr())),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final promotion = Promotion(
        id: widget.promotion?.id ?? '',
        choyxonaId: widget.choyxonaId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        discountPercent: int.parse(_discountController.text.trim()),
        startDate: _startDate,
        endDate: _endDate,
        promoCode: _promoCodeController.text.trim().toUpperCase(),
        isActive: _isActive,
        createdAt: widget.promotion?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (_isEditing) {
        await _promotionService.updatePromotion(promotion);
      } else {
        await _promotionService.createPromotion(promotion);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'promotion_updated'.tr() : 'promotion_created'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_saving'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_promotion'.tr()),
        content: Text('delete_promotion_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _promotionService.deletePromotion(widget.promotion!.id);
              if (mounted) Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }
}
