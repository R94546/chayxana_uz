import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import '../../models/choyxona_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../choyxona_details/choyxona_details_screen.dart';

/// Экран карты с Google Maps и маркерами всех чайхан
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<Choyxona> _choyxonas = [];
  Choyxona? _selectedChoyxona;
  bool _isLoading = true;
  String? _errorMessage;
  Position? _userPosition;
  
  // Центр Ташкента по умолчанию
  static const LatLng _tashkentCenter = LatLng(41.2995, 69.2401);
  
  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadChoyxonas();
  }
  
  /// Получение местоположения пользователя
  Future<void> _getUserLocation() async {
    try {
      // Проверяем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('DEBUG MapScreen: Геолокация отклонена');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('DEBUG MapScreen: Геолокация запрещена навсегда');
        return;
      }
      
      // Получаем позицию
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('DEBUG MapScreen: Позиция пользователя: ${position.latitude}, ${position.longitude}');
      
      if (mounted) {
        setState(() {
          _userPosition = position;
        });
        
        // Центрируем карту на пользователе
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    } catch (e) {
      print('ERROR MapScreen: Ошибка получения геолокации: $e');
    }
  }
  
  /// Расчёт расстояния между двумя точками (в км)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Pi/180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin(...)
  }
  
  /// Получение строки расстояния
  String _getDistanceString(Choyxona choyxona) {
    if (_userPosition == null) return '';
    
    final distance = _calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      choyxona.address.latitude,
      choyxona.address.longitude,
    );
    
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
  
  /// Сортировка чайхан по расстоянию
  List<Choyxona> _getSortedByDistance() {
    if (_userPosition == null) return _choyxonas;
    
    final sorted = List<Choyxona>.from(_choyxonas);
    sorted.sort((a, b) {
      final distA = _calculateDistance(
        _userPosition!.latitude,
        _userPosition!.longitude,
        a.address.latitude,
        a.address.longitude,
      );
      final distB = _calculateDistance(
        _userPosition!.latitude,
        _userPosition!.longitude,
        b.address.latitude,
        b.address.longitude,
      );
      return distA.compareTo(distB);
    });
    return sorted;
  }
  
  Future<void> _loadChoyxonas() async {
    try {
      print('DEBUG MapScreen: Начинаю загрузку чайхан...');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('choyxonas')
          .where('status', isEqualTo: 'active')
          .get();
      
      print('DEBUG MapScreen: Получено ${snapshot.docs.length} документов');
      
      final choyxonas = <Choyxona>[];
      final markers = <Marker>{};
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          print('DEBUG MapScreen: Чайхана: ${data['name']}');
          
          final choyxona = Choyxona.fromFirestore(doc);
          choyxonas.add(choyxona);
          
          final lat = choyxona.address.latitude;
          final lng = choyxona.address.longitude;
          
          // Создаём маркер
          if (lat != 0 || lng != 0) {
            markers.add(Marker(
              markerId: MarkerId(choyxona.id),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: choyxona.name,
                snippet: choyxona.address.fullAddress,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                choyxona.isOpenNow() 
                    ? BitmapDescriptor.hueGreen 
                    : BitmapDescriptor.hueRed,
              ),
              onTap: () {
                setState(() {
                  _selectedChoyxona = choyxona;
                });
              },
            ));
          }
        } catch (e) {
          print('ERROR MapScreen: Ошибка парсинга: $e');
        }
      }
      
      print('DEBUG MapScreen: Создано ${markers.length} маркеров');
      
      if (mounted) {
        setState(() {
          _choyxonas = choyxonas;
          _markers = markers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR MapScreen: Ошибка загрузки: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  /// Показать список чайхан
  void _showChoyxonasList() {
    final sorted = _getSortedByDistance();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Ручка
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Заголовок
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'all_choyxonas'.tr(),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${sorted.length}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_userPosition != null)
                      Row(
                        children: [
                          Icon(Icons.near_me, size: 16, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            "Yaqinlik bo'yicha",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Список
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final choyxona = sorted[index];
                    return _buildListItem(choyxona, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildListItem(Choyxona choyxona, bool isDark) {
    final distance = _getDistanceString(choyxona);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Закрыть bottom sheet
          
          // Центрировать карту на чайхане
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(choyxona.address.latitude, choyxona.address.longitude),
              15,
            ),
          );
          
          setState(() {
            _selectedChoyxona = choyxona;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Изображение
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  choyxona.mainImage,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                    child: Icon(Icons.restaurant, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            choyxona.name,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: choyxona.isOpenNow() ? AppColors.success : AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            choyxona.isOpenNow() ? 'open'.tr() : 'closed'.tr(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      choyxona.address.fullAddress,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Рейтинг
                        Icon(Icons.star, size: 14, color: AppColors.starGold),
                        const SizedBox(width: 4),
                        Text(
                          choyxona.rating.toStringAsFixed(1),
                          style: TextStyle(color: AppColors.starGold, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        if (distance.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          // Расстояние
                          Icon(Icons.near_me, size: 14, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('map_title'.tr()),
        elevation: 0,
        actions: [
          // Кликабельная кнопка со списком
          if (_choyxonas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: InkWell(
                  onTap: _showChoyxonasList,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list, size: 16, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          '${_markers.length} ${'on_map'.tr()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(isDark),
      // Кнопка центрирования на пользователе
      floatingActionButton: _userPosition != null
          ? FloatingActionButton.small(
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_userPosition!.latitude, _userPosition!.longitude),
                    14,
                  ),
                );
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.my_location, color: Colors.white),
            )
          : null,
    );
  }
  
  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Xarita yuklanmoqda...'),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Yuklashda xato', style: AppTextStyles.titleLarge),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadChoyxonas();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        // Google Maps
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _userPosition != null 
                ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                : _tashkentCenter,
            zoom: 12,
          ),
          markers: _markers,
          myLocationEnabled: true,  // Показывает синюю точку пользователя
          myLocationButtonEnabled: false, // Отключаем стандартную кнопку
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            print('DEBUG MapScreen: Карта создана!');
          },
          onTap: (_) {
            setState(() {
              _selectedChoyxona = null;
            });
          },
        ),
        
        // Пустое состояние
        if (_choyxonas.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_outlined,
                    size: 48,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textLight,
                  ),
                  const SizedBox(height: 12),
                  Text('no_choyxonas'.tr(), style: AppTextStyles.bodyLarge),
                ],
              ),
            ),
          ),
        
        // Карточка выбранной чайханы
        if (_selectedChoyxona != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildChoyxonaCard(_selectedChoyxona!, isDark),
          ),
      ],
    );
  }

  Widget _buildChoyxonaCard(Choyxona choyxona, bool isDark) {
    final distance = _getDistanceString(choyxona);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок с изображением
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  choyxona.mainImage,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                    child: Icon(
                      Icons.restaurant,
                      size: 48,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
                // Кнопка закрытия
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedChoyxona = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                // Статус и расстояние
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: choyxona.isOpenNow() ? AppColors.success : AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          choyxona.isOpenNow() ? 'open'.tr() : 'closed'.tr(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      if (distance.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                distance,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Информация
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        choyxona.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.starGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.starGold),
                          const SizedBox(width: 4),
                          Text(
                            choyxona.rating.toStringAsFixed(1),
                            style: const TextStyle(color: AppColors.starGold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  choyxona.address.fullAddress,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChoyxonaDetailsScreen(choyxona: choyxona),
                        ),
                      );
                    },
                    child: Text('details'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}