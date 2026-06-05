import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/choyxona_model.dart';
import '../../services/favorites_service.dart';
import '../../services/auth_service.dart';
import '../booking/booking_screen.dart';
import '../booking/availability_calendar_screen.dart';
import '../reviews/reviews_screen.dart';

/// 🎨 NEW ULTRA MODERN CHOYXONA DETAILS SCREEN
/// Matching the HTML/Tailwind design 1:1
class ChoyxonaDetailsScreen extends StatefulWidget {
  final Choyxona choyxona;

  const ChoyxonaDetailsScreen({
    super.key,
    required this.choyxona,
  });

  @override
  State<ChoyxonaDetailsScreen> createState() => _ChoyxonaDetailsScreenState();
}

class _ChoyxonaDetailsScreenState extends State<ChoyxonaDetailsScreen> {
  final _favoritesService = FavoritesService();
  final _authService = AuthService();
  final ScrollController _scrollController = ScrollController();
  
  bool _isFavorite = false;
  double _scrollOffset = 0.0;

  // 🎨 NEW DESIGN COLORS (matching HTML)
  static const Color _background = Color(0xFFFDFBF7);
  static const Color _foreground = Color(0xFF1C1C1E);
  static const Color _primary = Color(0xFF0D9488);
  static const Color _primaryForeground = Color(0xFFFFFFFF);
  static const Color _secondary = Color(0xFFF59E0B);
  static const Color _muted = Color(0xFFF0F3F5);
  static const Color _mutedForeground = Color(0xFF64748B);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkFavorite() async {
    final user = _authService.currentUser;
    if (user == null) return;
    
    final isFav = await _favoritesService.isFavorite(user.uid, widget.choyxona.id);
    if (mounted) {
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _authService.currentUser;
    if (user == null) return;
    
    final newState = await _favoritesService.toggleFavorite(user.uid, widget.choyxona.id);
    if (mounted) {
      setState(() => _isFavorite = newState);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState ? 'added_to_favorites'.tr() : 'removed_from_favorites'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          // 🎨 Background Pattern (Uzbek Arabesque)
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://www.transparenttextures.com/patterns/arabesque.png'),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),
          ),
          
          // Main Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildImageHeader(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVenueCard(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildAboutSection(),
                    const SizedBox(height: 24),
                    _buildFacilitiesSection(),
                    const SizedBox(height: 24),
                    _buildRatingsSection(),
                    const SizedBox(height: 24),
                    _buildWorkingHoursSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ],
          ),
          
          // Floating Header
          _buildFloatingHeader(),
          
          // Bottom Action Button
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Main Image with Parallax
            Transform.translate(
              offset: Offset(0, -_scrollOffset * 0.4),
              child: Hero(
                tag: 'choyxona_image_${widget.choyxona.id}',
                child: widget.choyxona.mainImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.choyxona.mainImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: _muted,
                          child: const Center(
                            child: CircularProgressIndicator(color: _primary),
                          ),
                        ),
                      )
                    : Container(
                        color: _muted,
                        child: const Icon(Icons.restaurant, size: 80, color: _mutedForeground),
                      ),
              ),
            ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                    _background,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeader() {
    final opacity = (_scrollOffset / 150).clamp(0.0, 1.0);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: _background.withOpacity(opacity * 0.95),
          border: Border(
            bottom: BorderSide(
              color: _border.withOpacity(opacity * 0.5),
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Back Button
                _buildHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 16),
                
                // Title (appears on scroll)
                Expanded(
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      widget.choyxona.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Favorite Button
                _buildHeaderButton(
                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                  onTap: _toggleFavorite,
                  color: _isFavorite ? Colors.red : null,
                ),
                const SizedBox(width: 8),
                
                // Share Button
                _buildHeaderButton(
                  icon: Icons.share_outlined,
                  onTap: () {
                    // TODO: Implement share
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 22,
          color: color ?? _foreground,
        ),
      ),
    );
  }

  Widget _buildVenueCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Venue Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.choyxona.mainImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.choyxona.mainImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: _muted,
                      child: const Icon(Icons.restaurant, color: _mutedForeground),
                    ),
            ),
            const SizedBox(width: 16),
            
            // Venue Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'choyxona_title_${widget.choyxona.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        widget.choyxona.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: _mutedForeground),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.choyxona.address.city}, ${widget.choyxona.address.region}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: _secondary),
                      const SizedBox(width: 4),
                      Text(
                        widget.choyxona.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _foreground,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.choyxona.reviewCount}+ reviews)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone_outlined,
              label: 'call'.tr(),
              onTap: () => _makePhoneCall(widget.choyxona.contacts.phone),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.calendar_month_outlined,
              label: 'calendar'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AvailabilityCalendarScreen(choyxona: widget.choyxona),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.directions_outlined,
              label: 'direction'.tr(),
              onTap: _openMaps,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _muted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _foreground,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('about'.tr()),
          const SizedBox(height: 12),
          Text(
            widget.choyxona.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: _mutedForeground,
            ),
          ),
          
          // Cuisine Tags
          if (widget.choyxona.cuisine.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.choyxona.cuisine.take(4).map((cuisine) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_secondary, Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _secondary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    cuisine,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    final facilities = widget.choyxona.features;
    if (facilities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('facilities'.tr()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border.withOpacity(0.5)),
            ),
            child: Column(
              children: facilities.asMap().entries.map((entry) {
                final isLast = entry.key == facilities.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReviewsScreen(
                choyxonaId: widget.choyxona.id,
                choyxonaName: widget.choyxona.name,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, Color(0xFF0F766E)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.choyxona.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < widget.choyxona.rating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: _secondary,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.choyxona.reviewCount} reviews',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkingHoursSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('working_hours'.tr()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border.withOpacity(0.5)),
            ),
            child: Column(
              children: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'].asMap().entries.map((entry) {
                final day = entry.value;
                final hours = widget.choyxona.workingHours[day];
                if (hours == null) return const SizedBox.shrink();
                
                final isToday = _isToday(day);
                final isLast = entry.key == 6;
                
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isToday)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                color: _primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            day.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                              color: isToday ? _primary : _foreground,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        hours.isOpen ? '${hours.open} - ${hours.close}' : 'Closed'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: hours.isOpen ? _mutedForeground : Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(String day) {
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final today = DateTime.now().weekday - 1;
    return weekdays[today] == day;
  }

  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('location'.tr()),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openMaps,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: _primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.choyxona.address.street,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _foreground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.choyxona.address.city}, ${widget.choyxona.address.region}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: _mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _background.withOpacity(0),
              _background,
              _background,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookingScreen(choyxona: widget.choyxona),
              ),
            );
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, Color(0xFF0F766E)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'book_table'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryForeground,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  color: _primaryForeground,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps() async {
    final lat = widget.choyxona.address.latitude;
    final lng = widget.choyxona.address.longitude;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
