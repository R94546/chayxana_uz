import 'package:firebase_analytics/firebase_analytics.dart';

/// Xizmat Analytics - Foydalanuvchi harakatlarini kuzatish
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  /// Ekran ko'rish
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  /// Kirish
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Ro'yxatdan o'tish
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// ID o'rnatish
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Bron qilish
  Future<void> logBooking({
    required String choyxonaId,
    required String choyxonaName,
    required int guestCount,
    required String date,
  }) async {
    await _analytics.logEvent(
      name: 'booking_created',
      parameters: {
        'choyxona_id': choyxonaId,
        'choyxona_name': choyxonaName,
        'guest_count': guestCount,
        'date': date,
      },
    );
  }

  /// Choyxonani ko'rish
  Future<void> logViewChoyxona(String choyxonaId, String name) async {
    await _analytics.logEvent(
      name: 'view_choyxona',
      parameters: {
        'choyxona_id': choyxonaId,
        'choyxona_name': name,
      },
    );
  }

  /// Sevimlilarga qo'shish
  Future<void> logAddToFavorites(String choyxonaId) async {
    await _analytics.logEvent(
      name: 'add_to_favorites',
      parameters: {'choyxona_id': choyxonaId},
    );
  }

  /// Sharh qoldirish
  Future<void> logReview(String choyxonaId, double rating) async {
    await _analytics.logEvent(
      name: 'submit_review',
      parameters: {
        'choyxona_id': choyxonaId,
        'rating': rating,
      },
    );
  }

  /// Qidiruv
  Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: query);
  }
}
