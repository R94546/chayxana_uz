import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

/// Сервис для работы с геолокацией
class LocationService {
  static LocationService? _instance;
  Position? _userPosition;
  bool _isInitialized = false;
  
  static LocationService get instance {
    _instance ??= LocationService._internal();
    return _instance!;
  }
  
  LocationService._internal();
  
  Position? get userPosition => _userPosition;
  bool get isInitialized => _isInitialized;
  
  /// Инициализация геолокации
  Future<Position?> initialize() async {
    if (_isInitialized && _userPosition != null) {
      return _userPosition;
    }
    
    try {
      // Проверяем доступность сервиса
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('DEBUG LocationService: Сервис геолокации отключен');
        return null;
      }
      
      // Проверяем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('DEBUG LocationService: Разрешение отклонено');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('DEBUG LocationService: Разрешение запрещено навсегда');
        return null;
      }
      
      // Получаем позицию
      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      _isInitialized = true;
      
      print('DEBUG LocationService: Позиция: ${_userPosition?.latitude}, ${_userPosition?.longitude}');
      return _userPosition;
    } catch (e) {
      print('ERROR LocationService: $e');
      return null;
    }
  }
  
  /// Расчёт расстояния между двумя точками (в км)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Pi/180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin(...)
  }
  
  /// Получение строки расстояния до координат
  String getDistanceString(double latitude, double longitude) {
    if (_userPosition == null || (latitude == 0 && longitude == 0)) {
      return '';
    }
    
    final distance = calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      latitude,
      longitude,
    );
    
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
  
  /// Обновить позицию
  Future<void> refresh() async {
    _isInitialized = false;
    await initialize();
  }
}
