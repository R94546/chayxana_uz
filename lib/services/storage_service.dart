import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/image_crop_screen.dart';

/// Модель для хранения выбранного изображения (кроссплатформенно)
class PickedImage {
  final XFile xFile;
  final Uint8List? bytes; // Для web
  
  PickedImage({required this.xFile, this.bytes});
  
  /// Получить bytes для отображения
  Future<Uint8List> getBytes() async {
    if (bytes != null) return bytes!;
    return await xFile.readAsBytes();
  }
  
  /// Create from bytes (after cropping)
  static PickedImage fromBytes(Uint8List bytes, String name) {
    return PickedImage(
      xFile: XFile.fromData(bytes, name: name, mimeType: 'image/jpeg'),
      bytes: bytes,
    );
  }
}

/// Сервис для работы с Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Выбор изображения из галереи
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Ошибка выбора изображения: $e');
      return null;
    }
  }

  /// Выбор изображения с камеры
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Ошибка захвата изображения: $e');
      return null;
    }
  }

  /// Загрузка изображения блюда в Firebase Storage
  Future<String?> uploadDishImage({
    required File imageFile,
    required String choyxonaId,
    required String dishId,
  }) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'dishes/$choyxonaId/$dishId/$fileName';
      
      final Reference ref = _storage.ref().child(path);
      
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Ошибка загрузки изображения блюда: $e');
      return null;
    }
  }

  /// Загрузка изображения чайханы
  Future<String?> uploadChoyxonaImage({
    required File imageFile,
    required String choyxonaId,
  }) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'choyxonas/$choyxonaId/images/$fileName';
      
      final Reference ref = _storage.ref().child(path);
      
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Ошибка загрузки изображения чайханы: $e');
      return null;
    }
  }

  /// Загрузка изображения из XFile (кроссплатформенно - работает на web!)
  Future<String?> uploadImageFromXFile({
    required XFile imageFile,
    required String path,
  }) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String fullPath = '$path/$fileName';
      
      final Reference ref = _storage.ref().child(fullPath);
      
      // Читаем bytes - работает на всех платформах
      final Uint8List bytes = await imageFile.readAsBytes();
      
      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
      return null;
    }
  }

  /// Загрузка изображения из PickedImage (кроссплатформенно)
  Future<String?> uploadPickedImage({
    required PickedImage image,
    required String path,
  }) async {
    return uploadImageFromXFile(imageFile: image.xFile, path: path);
  }

  /// Удаление изображения
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Ошибка удаления изображения: $e');
      return false;
    }
  }

  /// Загрузка галереи изображений чайханы (кроссплатформенно)
  Future<List<String>> uploadChoyxonaGallery({
    required List<PickedImage> imageFiles,
    required String choyxonaId,
  }) async {
    List<String> urls = [];
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final url = await uploadPickedImage(
          image: imageFiles[i],
          path: 'choyxonas/$choyxonaId/images',
        );
        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        print('Ошибка загрузки изображения $i: $e');
      }
    }
    return urls;
  }

  /// 🆕 Pick image with cropping (Telegram-style)
  Future<PickedImage?> pickAndCropImage(BuildContext context, {bool enableCrop = true}) async {
    final picked = await showImagePickerDialogCrossplatform(context);
    if (picked == null) return null;
    
    if (!enableCrop) return picked;
    
    // Open crop screen
    final bytes = await picked.getBytes();
    final croppedBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageCropScreen(imageBytes: bytes),
      ),
    );
    
    if (croppedBytes != null) {
      return PickedImage.fromBytes(croppedBytes, 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
    }
    
    return null;
  }


  /// Показ диалога выбора источника изображения (возвращает XFile - работает на web!)
  Future<PickedImage?> showImagePickerDialogCrossplatform(BuildContext context) async {
    // На web камера обычно не доступна, показываем только галерею
    ImageSource source = ImageSource.gallery;
    
    if (!kIsWeb) {
      final ImageSource? selectedSource = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Manbani tanlang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.photo_library, color: Colors.white),
                  ),
                  title: const Text('Galereya'),
                  subtitle: const Text('Galereyadan tanlash'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.camera_alt, color: Colors.white),
                  ),
                  title: const Text('Kamera'),
                  subtitle: const Text('Rasm olish'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
      
      if (selectedSource == null) return null;
      source = selectedSource;
    }
    
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Читаем bytes сразу для web
        final Uint8List bytes = await image.readAsBytes();
        return PickedImage(xFile: image, bytes: bytes);
      }
    } catch (e) {
      print('Ошибка выбора изображения: $e');
    }
    
    return null;
  }

  /// Показ диалога выбора источника изображения (для обратной совместимости)
  Future<File?> showImagePickerDialog(BuildContext context) async {
    if (kIsWeb) {
      // На web возвращаем null, используйте showImagePickerDialogCrossplatform
      print('Warning: showImagePickerDialog не поддерживается на web. Используйте showImagePickerDialogCrossplatform');
      return null;
    }
    
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Выберите источник',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Галерея'),
                subtitle: const Text('Выбрать из галереи'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: const Text('Камера'),
                subtitle: const Text('Сделать фото'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
    
    if (source == null) return null;
    
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Ошибка выбора изображения: $e');
    }
    
    return null;
  }
}
