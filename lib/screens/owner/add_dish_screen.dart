import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/dish_model.dart';
import '../../services/menu_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Экран добавления блюда
class AddDishScreen extends StatefulWidget {
  final String choyxonaId;

  const AddDishScreen({
    super.key,
    required this.choyxonaId,
  });

  @override
  State<AddDishScreen> createState() => _AddDishScreenState();
}

class _AddDishScreenState extends State<AddDishScreen> {
  final _formKey = GlobalKey<FormState>();
  final MenuService _menuService = MenuService();
  final StorageService _storageService = StorageService();

  // Изображение
  File? _selectedImage;
  bool _isUploadingImage = false;


  // Контроллеры
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _preparationTimeController = TextEditingController();

  // Значения
  String _selectedCategory = 'main';
  bool _isPopular = false;
  bool _isSpicy = false;
  bool _isVegetarian = false;
  bool _isLoading = false;

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
        title: const Text('Добавить блюдо'),
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
            _buildImagePicker(),
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
        hintText: 'Например: Плов',
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
        hintText: 'Опишите блюдо',
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
        hintText: '35000',
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
        hintText: '30',
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
          subtitle: const Text('Будет отображаться в разделе популярных'),
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
          subtitle: const Text('Содержит острые специи'),
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
          subtitle: const Text('Без мяса и рыбы'),
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

  /// Image picker widget
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Фото блюда',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Нажмите, чтобы добавить фото',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage() async {
    final image = await _storageService.showImagePickerDialog(context);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  /// Кнопка сохранения
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveDish,
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
              'Сохранить',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  /// Сохранить блюдо
  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = '';
      
      // Если выбрано изображение - загружаем его в Storage
      if (_selectedImage != null) {
        final tempDishId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await _storageService.uploadDishImage(
          imageFile: _selectedImage!,
          choyxonaId: widget.choyxonaId,
          dishId: tempDishId,
        ) ?? '';
      }

      // Создаём модель блюда
      final dish = DishModel(
        dishId: '', // Будет сгенерирован Firestore
        choyxonaId: widget.choyxonaId,
        name: _nameController.text.trim(),
        nameUz: _nameController.text.trim(),
        nameRu: _nameController.text.trim(),
        nameEn: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        descriptionUz: _descriptionController.text.trim(),
        descriptionRu: _descriptionController.text.trim(),
        descriptionEn: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        imageUrl: imageUrl,
        isAvailable: true,
        isPopular: _isPopular,
        isSpicy: _isSpicy,
        isVegetarian: _isVegetarian,
        preparationTime: _preparationTimeController.text.isNotEmpty
            ? int.parse(_preparationTimeController.text)
            : 30,
        orderCount: 0,
        rating: 0,
        reviewCount: 0,
        allergens: [],
        ingredients: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем
      final error = await _menuService.addDish(dish);

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
            content: Text('Блюдо успешно добавлено!'),
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
