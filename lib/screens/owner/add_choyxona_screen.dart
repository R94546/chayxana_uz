import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

/// Форма добавления новой чайханы
class AddChoyxonaScreen extends StatefulWidget {
  const AddChoyxonaScreen({super.key});

  @override
  State<AddChoyxonaScreen> createState() => _AddChoyxonaScreenState();
}

class _AddChoyxonaScreenState extends State<AddChoyxonaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _capacityController = TextEditingController();
  final _tableCountController = TextEditingController();
  final _latitudeController = TextEditingController(text: '41.311081');
  final _longitudeController = TextEditingController(text: '69.240562');

  // Изображения (используем PickedImage для кроссплатформенности)
  final StorageService _storageService = StorageService();
  List<PickedImage> _selectedImages = [];

  String _selectedCategory = 'traditional';
  String _selectedPriceRange = '\$\$';
  List<String> _selectedCuisines = ['uzbek'];
  List<String> _selectedFeatures = [];

  bool _isLoading = false;

  final List<Map<String, String>> _categories = [
    {'value': 'traditional', 'label': '🍲 Традиционная'},
    {'value': 'modern', 'label': '✨ Современная'},
    {'value': 'fast_casual', 'label': '⚡ Быстрая'},
    {'value': 'fine_dining', 'label': '👑 Премиум'},
  ];

  final List<Map<String, String>> _cuisineTypes = [
    {'value': 'uzbek', 'label': 'Узбекская'},
    {'value': 'oriental', 'label': 'Восточная'},
    {'value': 'european', 'label': 'Европейская'},
    {'value': 'asian', 'label': 'Азиатская'},
  ];

  final List<Map<String, String>> _features = [
    {'value': 'wifi', 'label': 'WiFi'},
    {'value': 'parking', 'label': 'Парковка'},
    {'value': 'live_music', 'label': 'Живая музыка'},
    {'value': 'kids_area', 'label': 'Детская зона'},
    {'value': 'hookah', 'label': 'Кальян'},
    {'value': 'outdoor_seating', 'label': 'Терраса'},
    {'value': 'air_conditioning', 'label': 'Кондиционер'},
    {'value': 'credit_cards', 'label': 'Оплата картой'},
    {'value': 'delivery', 'label': 'Доставка'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _capacityController.dispose();
    _tableCountController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Добавить чайхану'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              _buildSectionTitle('Основная информация'),
              _buildTextField(
                controller: _nameController,
                label: 'Название',
                hint: 'Чайхана Навруз',
                validator: (v) => v?.isEmpty ?? true ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Описание',
                hint: 'Расскажите о вашей чайхане...',
                maxLines: 4,
                validator: (v) => v?.isEmpty ?? true ? 'Введите описание' : null,
              ),

              const SizedBox(height: 24),

              // Ценовой диапазон (moved up)

              // Ценовой диапазон
              _buildSectionTitle('Ценовой диапазон'),
              _buildPriceRangeSelector(),

              const SizedBox(height: 24),

              // Фото
              _buildSectionTitle('Фото (добавьте до 10 фото)'),
              _buildImagePicker(),

              const SizedBox(height: 24),

              // Адрес
              _buildSectionTitle('Адрес'),
              _buildTextField(
                controller: _streetController,
                label: 'Улица',
                hint: 'ул. Амира Темура, 12',
                validator: (v) => v?.isEmpty ?? true ? 'Введите улицу' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'Город',
                      hint: 'Ташкент',
                      validator: (v) => v?.isEmpty ?? true ? 'Введите город' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _districtController,
                      label: 'Район',
                      hint: 'Юнусабадский',
                      validator: (v) => v?.isEmpty ?? true ? 'Введите район' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              
              // Координаты для карты
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latitudeController,
                      label: 'Широта (lat)',
                      hint: '41.311081',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _longitudeController,
                      label: 'Долгота (lng)',
                      hint: '69.240562',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '💡 Найдите координаты в Google Maps',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

              const SizedBox(height: 24),

              // Контакты
              _buildSectionTitle('Контакты'),
              _buildTextField(
                controller: _phoneController,
                label: 'Телефон',
                hint: '+998901234567',
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Введите телефон' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email (опционально)',
                hint: 'info@choyxona.uz',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 24),

              // Вместимость
              _buildSectionTitle('Вместимость'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _capacityController,
                      label: 'Всего мест',
                      hint: '80',
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true ? 'Введите вместимость' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _tableCountController,
                      label: 'Столов',
                      hint: '15',
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true ? 'Введите кол-во столов' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Особенности
              _buildSectionTitle('Особенности'),
              _buildFeaturesSelector(),

              const SizedBox(height: 32),

              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChoyxona,
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textWhite,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Сохранить чайхану'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.titleLarge,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      validator: validator,
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category['value']!;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              category['label']!,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCuisineSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _cuisineTypes.map((cuisine) {
        final isSelected = _selectedCuisines.contains(cuisine['value']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCuisines.remove(cuisine['value']);
              } else {
                _selectedCuisines.add(cuisine['value']!);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              cuisine['label']!,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeSelector() {
    final ranges = ['\$', '\$\$', '\$\$\$', '\$\$\$\$'];
    return Row(
      children: ranges.map((range) {
        final isSelected = _selectedPriceRange == range;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPriceRange = range;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                range,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected ? AppColors.textWhite : AppColors.accent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturesSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _features.map((feature) {
        final isSelected = _selectedFeatures.contains(feature['value']);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedFeatures.remove(feature['value']);
              } else {
                _selectedFeatures.add(feature['value']!);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.primary,
                  ),
                if (isSelected) const SizedBox(width: 4),
                Text(
                  feature['label']!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Виджет выбора фото
  Widget _buildImagePicker() {
    return Column(
      children: [
        // Кнопка добавления фото
        GestureDetector(
          onTap: _selectedImages.length < 10 ? _pickImage : null,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: _selectedImages.length < 10 
                      ? AppColors.primary 
                      : AppColors.textLight,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedImages.isEmpty
                      ? 'Нажмите, чтобы добавить фото'
                      : '${_selectedImages.length}/10 фото',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Превью выбранных фото
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<dynamic>(
                          future: _selectedImages[index].getBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
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
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Главное',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Выбор фото с кадрированием (кроссплатформенно)
  Future<void> _pickImage() async {
    try {
      final image = await _storageService.pickAndCropImage(context);
      print('DEBUG: Image picked and cropped: $image');
      if (image != null && _selectedImages.length < 10) {
        setState(() {
          _selectedImages.add(image);
        });
        print('DEBUG: Image added, total: ${_selectedImages.length}');
      } else if (image == null) {
        print('DEBUG: Image is null');
      }
    } catch (e) {
      print('DEBUG: Error picking image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rasm tanlashda xatolik: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveChoyxona() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCuisines.isEmpty) {
      _showError('Выберите хотя бы один тип кухни');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await AuthService().getCurrentUserData();
      if (currentUser == null) {
        _showError('Пользователь не авторизован');
        return;
      }

      // Загружаем фото в Firebase Storage
      List<String> imageUrls = [];
      String mainImageUrl = '';
      
      if (_selectedImages.isNotEmpty) {
        // Генерируем временный ID для папки
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrls = await _storageService.uploadChoyxonaGallery(
          imageFiles: _selectedImages,
          choyxonaId: tempId,
        );
        if (imageUrls.isNotEmpty) {
          mainImageUrl = imageUrls.first;
        }
      }

      // Создаём документ чайханы
      final choyxonaData = {
        'name': _nameController.text.trim(),
        'nameUz': _nameController.text.trim(),
        'nameRu': _nameController.text.trim(),
        'nameEn': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'images': imageUrls,
        'mainImage': mainImageUrl,
        'category': _selectedCategory,
        'cuisine': _selectedCuisines,
        'address': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'district': _districtController.text.trim(),
          'region': _cityController.text.trim(),
          'country': 'Узбекистан',
          'postalCode': '100000',
          'latitude': double.tryParse(_latitudeController.text) ?? 41.311081,
          'longitude': double.tryParse(_longitudeController.text) ?? 69.240562,
        },
        'contacts': {
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'website': '',
          'instagram': '',
          'telegram': '',
        },
        'workingHours': {
          'monday': {'open': '08:00', 'close': '23:00', 'isOpen': true},
          'tuesday': {'open': '08:00', 'close': '23:00', 'isOpen': true},
          'wednesday': {'open': '08:00', 'close': '23:00', 'isOpen': true},
          'thursday': {'open': '08:00', 'close': '23:00', 'isOpen': true},
          'friday': {'open': '08:00', 'close': '00:00', 'isOpen': true},
          'saturday': {'open': '08:00', 'close': '00:00', 'isOpen': true},
          'sunday': {'open': '08:00', 'close': '23:00', 'isOpen': true},
        },
        'features': _selectedFeatures,
        'priceRange': _selectedPriceRange,
        'capacity': int.tryParse(_capacityController.text) ?? 0,
        'tableCount': int.tryParse(_tableCountController.text) ?? 0,
        'rating': 4.5,
        'reviewCount': 0,
        'bookingCount': 0,
        'ownerId': currentUser.userId,
        'adminIds': [],
        'status': 'active',
        'isVerified': false,
        'isFeatured': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('choyxonas')
          .add(choyxonaData);

      if (!mounted) return;

      // Показываем успех и возвращаемся
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Чайхана успешно добавлена! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      _showError('Ошибка: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}