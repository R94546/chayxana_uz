import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 📱 Сервис интеграции с социальными сетями
class SocialService {
  /// Поделиться чайханой
  static Future<void> shareChoyxona({
    required String choyxonaName,
    required String description,
    required String choyxonaId,
  }) async {
    final url = 'https://choyxona.uz/choyxona/$choyxonaId';
    await Share.share(
      '🍽️ $choyxonaName\n\n$description\n\nСмотреть: $url',
      subject: choyxonaName,
    );
  }

  /// Поделиться меню
  static Future<void> shareMenu({
    required String choyxonaName,
    required String choyxonaId,
  }) async {
    final url = 'https://choyxona.uz/menu/$choyxonaId';
    await Share.share(
      '📱 Меню $choyxonaName\n\nСканируйте QR или перейдите по ссылке:\n$url',
      subject: 'Меню - $choyxonaName',
    );
  }

  /// Поделиться акцией
  static Future<void> sharePromotion({
    required String choyxonaName,
    required String promotionTitle,
    required int discountPercent,
    required String? promoCode,
  }) async {
    String message = '🎉 $promotionTitle\n\n'
        '📍 $choyxonaName\n'
        '💰 Скидка $discountPercent%\n';
    
    if (promoCode != null && promoCode.isNotEmpty) {
      message += '🎁 Промокод: $promoCode\n';
    }
    
    await Share.share(message, subject: promotionTitle);
  }

  /// Открыть в Telegram
  static Future<void> openInTelegram(String username) async {
    final telegramUrl = Uri.parse('https://t.me/$username');
    if (await canLaunchUrl(telegramUrl)) {
      await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Открыть в Instagram
  static Future<void> openInInstagram(String username) async {
    final instagramUrl = Uri.parse('https://instagram.com/$username');
    if (await canLaunchUrl(instagramUrl)) {
      await launchUrl(instagramUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Открыть в Facebook
  static Future<void> openInFacebook(String pageId) async {
    final facebookUrl = Uri.parse('https://facebook.com/$pageId');
    if (await canLaunchUrl(facebookUrl)) {
      await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Позвонить
  static Future<void> makePhoneCall(String phoneNumber) async {
    final phoneUrl = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(phoneUrl)) {
      await launchUrl(phoneUrl);
    }
  }

  /// Написать в WhatsApp
  static Future<void> openWhatsApp(String phoneNumber, {String? message}) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final whatsappUrl = Uri.parse(
      'https://wa.me/$cleanNumber${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}'
    );
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Открыть карты для навигации
  static Future<void> openMaps({
    required double latitude,
    required double longitude,
    String? name,
  }) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude'
    );
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }
}
