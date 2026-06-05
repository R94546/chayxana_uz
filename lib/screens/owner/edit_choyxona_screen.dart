import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/storage_service.dart';
import '../../models/choyxona_model.dart'; // Import for WorkingHours model

/// Экран редактирования чайханы
class EditChoyxonaScreen extends StatefulWidget {
  final String choyxonaId;
  final Map<String, dynamic> choyxonaData;

  const EditChoyxonaScreen({
    super.key,
    required this.choyxonaId,
    required this.choyxonaData,
  });

  @override
  State<EditChoyxonaScreen> createState() => _EditChoyxonaScreenState();
}

class _EditChoyxonaScreenState extends State<EditChoyxonaScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _capacityController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  
  List<String> _existingImages = [];
  List<PickedImage> _newImages = [];
  bool _isLoading = false;
  String _selectedCategory = 'traditional';
  String _selectedPriceRange = '\$\$';
  Map<String, WorkingHours> _workingHours = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.choyxonaData['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.choyxonaData['description'] ?? '');
    _streetController = TextEditingController(text: widget.choyxonaData['address']?['street'] ?? '');
    _cityController = TextEditingController(text: widget.choyxonaData['address']?['city'] ?? '');
    _phoneController = TextEditingController(text: widget.choyxonaData['contacts']?['phone'] ?? '');
    _capacityController = TextEditingController(text: widget.choyxonaData['capacity']?.toString() ?? '');
    _latitudeController = TextEditingController(text: widget.choyxonaData['address']?['latitude']?.toString() ?? '');
    _longitudeController = TextEditingController(text: widget.choyxonaData['address']?['longitude']?.toString() ?? '');
    _selectedCategory = widget.choyxonaData['category'] ?? 'traditional';
    _selectedPriceRange = widget.choyxonaData['priceRange'] ?? '\$\$';
    _existingImages = List<String>.from(widget.choyxonaData['images'] ?? []);
    
    // Initialize working hours
    if (widget.choyxonaData['workingHours'] != null) {
       final hoursMap = widget.choyxonaData['workingHours'] as Map<String, dynamic>;
       _workingHours = hoursMap.map((key, value) => MapEntry(key, WorkingHours.fromMap(value)));
    } else {
       // Default: Mon-Sun 09:00 - 23:00
       final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
       for (var day in days) {
         _workingHours[day] = WorkingHours(open: '09:00', close: '23:00', isOpen: true);
       }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _capacityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('edit_choyxona'.tr()),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Фото
              _buildSectionTitle('photos'.tr()),
              _buildImageSection(),
              const SizedBox(height: 24),
              
              // Основная информация
              _buildSectionTitle('basic_info'.tr()),
              _buildTextField(
                controller: _nameController,
                label: 'name'.tr(),
                hint: 'choyxona_name_hint'.tr(),
                validator: (v) => v?.isEmpty ?? true ? 'required_field'.tr() : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'description'.tr(),
                hint: 'description_hint'.tr(),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Категория
              _buildSectionTitle('category'.tr()),
              _buildCategorySelector(),
              const SizedBox(height: 24),
              
              // Ценовой диапазон
              _buildSectionTitle('price_range'.tr()),
              _buildPriceRangeSelector(),
              const SizedBox(height: 24),
              
              // Адрес
              _buildSectionTitle('address'.tr()),
              _buildTextField(
                controller: _streetController,
                label: 'street'.tr(),
                hint: 'street_hint'.tr(),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _cityController,
                label: 'city'.tr(),
                hint: 'city_hint'.tr(),
              ),
              const SizedBox(height: 16),
              
              // Koordinatalar
              _buildSectionTitle('Koordinatalar'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latitudeController,
                      label: 'Latitude',
                      hint: '41.299496',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _longitudeController,
                      label: 'Longitude',
                      hint: '69.240073',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Контакты
              _buildSectionTitle('contacts'.tr()),
              _buildTextField(
                controller: _phoneController,
                label: 'phone'.tr(),
                hint: '+998...',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              
              // Вместимость
              _buildSectionTitle('capacity'.tr()),
              _buildTextField(
                controller: _capacityController,
                label: 'total_seats'.tr(),
                hint: '80',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Рабочие часы
              _buildSectionTitle('working_hours'.tr()),
              _buildWorkingHoursSelector(),
              const SizedBox(height: 32),
              
              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: Text('save_changes'.tr()),
                ),
              ),
              const SizedBox(height: 16),
              
              // Кнопка удаления
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: Text('delete_choyxona'.tr()),
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
      child: Text(title, style: AppTextStyles.titleMedium),
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

  Widget _buildImageSection() {
    return Column(
      children: [
        // Существующие фото
        if (_existingImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _existingImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 100,
                            height: 100,
                            color: AppColors.surface,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _existingImages.removeAt(index);
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
                              size: 14,
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
        
        // Новые добавленные фото
        if (_newImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _newImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<dynamic>(
                            future: _newImages[index].getBytes(),
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
                                _newImages.removeAt(index);
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
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Новое',
                              style: TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Кнопка добавления фото
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_photo_alternate, color: AppColors.primary),
                const SizedBox(height: 4),
                Text('add_photo'.tr(), style: AppTextStyles.labelSmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'value': 'traditional', 'label': 'traditional'.tr()},
      {'value': 'modern', 'label': 'modern'.tr()},
      {'value': 'fast_casual', 'label': 'fast_casual'.tr()},
      {'value': 'fine_dining', 'label': 'fine_dining'.tr()},
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat['value']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              cat['label']!,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
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
            onTap: () => setState(() => _selectedPriceRange = range),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                range,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkingHoursSelector() {
    final days = [
      {'key': 'monday', 'label': 'monday'.tr()},
      {'key': 'tuesday', 'label': 'tuesday'.tr()},
      {'key': 'wednesday', 'label': 'wednesday'.tr()},
      {'key': 'thursday', 'label': 'thursday'.tr()},
      {'key': 'friday', 'label': 'friday'.tr()},
      {'key': 'saturday', 'label': 'saturday'.tr()},
      {'key': 'sunday', 'label': 'sunday'.tr()},
    ];

    return Column(
      children: days.map((day) {
        final key = day['key']!;
        final label = day['label']!;
        final hours = _workingHours[key] ?? WorkingHours(open: '09:00', close: '23:00', isOpen: true);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Switch(
                      value: hours.isOpen,
                      onChanged: (val) {
                        setState(() {
                          _workingHours[key] = WorkingHours(
                            open: hours.open,
                            close: hours.close,
                            isOpen: val,
                          );
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
                if (hours.isOpen)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _pickTime(context, key, true, hours.open),
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(hours.open),
                        ),
                      ),
                      const Text(' - '),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _pickTime(context, key, false, hours.close),
                          icon: const Icon(Icons.access_time_filled, size: 16),
                          label: Text(hours.close),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickTime(BuildContext context, String dayKey, bool isOpenTime, String currentTimeStr) async {
    final parts = currentTimeStr.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface,
              dialHandColor: AppColors.primary,
              dialBackgroundColor: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        final current = _workingHours[dayKey]!;
        _workingHours[dayKey] = WorkingHours(
          open: isOpenTime ? formatted : current.open,
          close: isOpenTime ? current.close : formatted,
          isOpen: current.isOpen,
        );
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final image = await _storageService.pickAndCropImage(context);
      print('DEBUG: Edit screen - Image picked and cropped: $image');
      if (image != null) {
        setState(() {
          _newImages.add(image);
        });
        print('DEBUG: New image added, total: ${_newImages.length}');
      } else {
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Загружаем новые фото
      List<String> newImageUrls = [];
      if (_newImages.isNotEmpty) {
        newImageUrls = await _storageService.uploadChoyxonaGallery(
          imageFiles: _newImages,
          choyxonaId: widget.choyxonaId,
        );
      }
      
      final allImages = [..._existingImages, ...newImageUrls];
      
      // Обновляем данные
      await FirebaseFirestore.instance
          .collection('choyxonas')
          .doc(widget.choyxonaId)
          .update({
        'name': _nameController.text.trim(),
        'nameRu': _nameController.text.trim(),
        'nameUz': _nameController.text.trim(),
        'nameEn': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'priceRange': _selectedPriceRange,
        'images': allImages,
        'mainImage': allImages.isNotEmpty ? allImages.first : '',
        'address.street': _streetController.text.trim(),
        'address.city': _cityController.text.trim(),
        'address.latitude': double.tryParse(_latitudeController.text.trim()) ?? 0.0,
        'address.longitude': double.tryParse(_longitudeController.text.trim()) ?? 0.0,
        'contacts.phone': _phoneController.text.trim(),
        'capacity': int.tryParse(_capacityController.text) ?? 0,
        'workingHours': _workingHours.map((key, value) => MapEntry(key, value.toMap())),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('changes_saved'.tr()),
          backgroundColor: AppColors.success,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error'.tr() + ': $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_choyxona'.tr()),
        content: Text('delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        await FirebaseFirestore.instance
            .collection('choyxonas')
            .doc(widget.choyxonaId)
            .delete();
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('deleted'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error'.tr() + ': $e'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
