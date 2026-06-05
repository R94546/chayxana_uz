import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/dish_model.dart';
import '../../services/menu_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран редактирования блюда
class EditDishScreen extends StatefulWidget {
  final DishModel dish;

  const EditDishScreen({
    super.key,
    required this.dish,
  });

  @override
  State<EditDishScreen> createState() => _EditDishScreenState();
}

class _EditDishScreenState extends State<EditDishScreen> {
  final _formKey = GlobalKey<FormState>();
  final MenuService _menuService = MenuService();

  // Контроллеры
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _preparationTimeController;

  // Значения
  late String _selectedCategory;
  late bool _isPopular;
  late bool _isSpicy;
  late bool _isVegetarian;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dish.name);
    _descriptionController = TextEditingController(text: widget.dish.description);
    _priceController = TextEditingController(text: widget.dish.price.toStringAsFixed(0));
    _preparationTimeController = TextEditingController(
      text: widget.dish.preparationTime.toString(),
    );
    _selectedCategory = widget.dish.category;
    _isPopular = widget.dish.isPopular;
    _isSpicy = widget.dish.isSpicy;
    _isVegetarian = widget.dish.isVegetarian;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать блюдо'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNameField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildPriceField(),
            const SizedBox(height: 16),
            _buildCategoryField(),
            const SizedBox(height: 16),
            _buildPreparationTimeField(),
            const SizedBox(height: 24),
            _buildCheckboxes(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// Поле названия
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Название блюда *',
        prefixIcon: const Icon(Icons.restaurant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Введите название';
        }
        if (value.trim().length < 2) {
          return 'Минимум 2 символа';
        }
        return null;
      },
    );
  }

  /// Поле описания
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Описание *',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Введите описание';
        }
        if (value.trim().length < 10) {
          return 'Минимум 10 символов';
        }
        return null;
      },
    );
  }

  /// Поле цены
  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: InputDecoration(
        labelText: 'Цена (сум) *',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Введите цену';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Цена должна быть больше 0';
        }
        return null;
      },
    );
  }

  /// Поле категории
  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Категория *',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'main',
          child: Text('🍽️ Основные блюда'),
        ),
        DropdownMenuItem(
          value: 'appetizer',
          child: Text('🥗 Закуски'),
        ),
        DropdownMenuItem(
          value: 'drink',
          child: Text('🥤 Напитки'),
        ),
        DropdownMenuItem(
          value: 'dessert',
          child: Text('🍰 Десерты'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  /// Поле времени приготовления
  Widget _buildPreparationTimeField() {
    return TextFormField(
      controller: _preparationTimeController,
      decoration: InputDecoration(
        labelText: 'Время приготовления (минуты)',
        prefixIcon: const Icon(Icons.timer),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final time = int.tryParse(value);
          if (time == null || time <= 0) {
            return 'Время должно быть больше 0';
          }
        }
        return null;
      },
    );
  }

  /// Чекбоксы
  Widget _buildCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дополнительно',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Популярное блюдо'),
          value: _isPopular,
          onChanged: (value) {
            setState(() {
              _isPopular = value ?? false;
            });
          },
          activeColor: AppColors.primary,
        ),
        CheckboxListTile(
          title: const Text('Острое'),
          value: _isSpicy,
          onChanged: (value) {
            setState(() {
              _isSpicy = value ?? false;
            });
          },
          activeColor: Colors.red,
        ),
        CheckboxListTile(
          title: const Text('Вегетарианское'),
          value: _isVegetarian,
          onChanged: (value) {
            setState(() {
              _isVegetarian = value ?? false;
            });
          },
          activeColor: Colors.green,
        ),
      ],
    );
  }

  /// Кнопка сохранения
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _updateDish,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Сохранить изменения',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  /// Обновить блюдо
  Future<void> _updateDish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'nameUz': _nameController.text.trim(),
        'nameRu': _nameController.text.trim(),
        'nameEn': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'descriptionUz': _descriptionController.text.trim(),
        'descriptionRu': _descriptionController.text.trim(),
        'descriptionEn': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'category': _selectedCategory,
        'isPopular': _isPopular,
        'isSpicy': _isSpicy,
        'isVegetarian': _isVegetarian,
        'preparationTime': int.parse(_preparationTimeController.text),
      };

      final error = await _menuService.updateDish(widget.dish.dishId, updates);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Изменения сохранены!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Подтверждение удаления
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить блюдо?'),
        content: Text(
          'Вы уверены, что хотите удалить "${widget.dish.name}"? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDish();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  /// Удалить блюдо
  Future<void> _deleteDish() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final error = await _menuService.deleteDish(widget.dish.dishId);

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Блюдо удалено'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
