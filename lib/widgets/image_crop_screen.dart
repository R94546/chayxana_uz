import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_layout.dart';

/// 📐 Telegram/WhatsApp-style Image Crop Screen
/// Responsive aspect ratios: Mobile 4:3, Tablet 3:2, Desktop 16:9
class ImageCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String? title;

  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    this.title,
  });

  /// Get device-appropriate aspect ratio
  static double getAspectRatio(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 16 / 9;
    if (ResponsiveLayout.isTablet(context)) return 3 / 2;
    return 4 / 3; // Mobile
  }

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  // Transform values
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;
  
  ui.Image? _image;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aspectRatio = ImageCropScreen.getAspectRatio(context);
    
    // Label for aspect ratio
    String ratioLabel;
    if (ResponsiveLayout.isDesktop(context)) {
      ratioLabel = '16:9 (Desktop)';
    } else if (ResponsiveLayout.isTablet(context)) {
      ratioLabel = '3:2 (Tablet)';
    } else {
      ratioLabel = '4:3 (Mobil)';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? 'Rasmni kesish'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : () => _cropAndReturn(aspectRatio),
            icon: const Icon(Icons.check, color: AppColors.success),
            label: Text(
              'Tayyor',
              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Aspect ratio indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ratioLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Crop area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate crop frame size
                      final frameWidth = constraints.maxWidth * 0.9;
                      final frameHeight = frameWidth / aspectRatio;
                      
                      return Stack(
                        children: [
                          // Image with gestures
                          Center(
                            child: GestureDetector(
                              onScaleStart: (details) {
                                _previousScale = _scale;
                                _previousOffset = _offset;
                              },
                              onScaleUpdate: (details) {
                                setState(() {
                                  _scale = (_previousScale * details.scale).clamp(0.5, 4.0);
                                  _offset = _previousOffset + details.focalPointDelta;
                                });
                              },
                              child: Transform.translate(
                                offset: _offset,
                                child: Transform.scale(
                                  scale: _scale,
                                  child: RawImage(image: _image),
                                ),
                              ),
                            ),
                          ),
                          
                          // Overlay with crop frame cutout
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: _CropOverlayPainter(
                                frameWidth: frameWidth,
                                frameHeight: frameHeight,
                              ),
                            ),
                          ),
                          
                          // Frame border
                          Center(
                            child: Container(
                              width: frameWidth,
                              height: frameHeight,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          
                          // Corner handles
                          Center(
                            child: SizedBox(
                              width: frameWidth,
                              height: frameHeight,
                              child: Stack(
                                children: [
                                  // Top-left
                                  Positioned(top: -4, left: -4, child: _buildCorner()),
                                  // Top-right
                                  Positioned(top: -4, right: -4, child: _buildCorner()),
                                  // Bottom-left
                                  Positioned(bottom: -4, left: -4, child: _buildCorner()),
                                  // Bottom-right
                                  Positioned(bottom: -4, right: -4, child: _buildCorner()),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Rasmni siljitish va kattalashtirish uchun suring',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Zoom controls
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() => _scale = (_scale - 0.2).clamp(0.5, 4.0)),
                  icon: const Icon(Icons.zoom_out, color: Colors.white),
                ),
                Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_scale - 0.5) / 3.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _scale = (_scale + 0.2).clamp(0.5, 4.0)),
                  icon: const Icon(Icons.zoom_in, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Future<void> _cropAndReturn(double aspectRatio) async {
    // For now, return original bytes
    // Full cropping implementation would use image package
    Navigator.pop(context, widget.imageBytes);
  }
}

/// Paints the dark overlay with a rectangular cutout
class _CropOverlayPainter extends CustomPainter {
  final double frameWidth;
  final double frameHeight;

  _CropOverlayPainter({required this.frameWidth, required this.frameHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    
    final center = Offset(size.width / 2, size.height / 2);
    final frameRect = Rect.fromCenter(
      center: center,
      width: frameWidth,
      height: frameHeight,
    );
    
    // Draw overlay with hole
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(8)))
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
