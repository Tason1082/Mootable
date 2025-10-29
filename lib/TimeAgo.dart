// lib/utils/time_ago.dart
// 🔹 Cihazın diline göre "x zaman önce" veya "x time ago" formatında tarih döndürür.

import 'dart:ui';

class TimeAgo {
  static String format(DateTime date, {String? locale}) {
    // Eğer locale verilmemişse cihazın sistem dilini al
    locale ??= PlatformDispatcher.instance.locale.languageCode;

    final now = DateTime.now();
    final difference = now.difference(date);

    // Eğer cihaz dili Türkçe değilse İngilizceye geç
    final isTurkish = locale.startsWith('tr');

    if (!isTurkish) {
      // 🔹 İngilizce biçimi
      if (difference.inSeconds < 60) {
        return "just now";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago";
      } else if (difference.inHours < 24) {
        return "${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago";
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return "$weeks week${weeks == 1 ? '' : 's'} ago";
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return "$months month${months == 1 ? '' : 's'} ago";
      } else {
        final years = (difference.inDays / 365).floor();
        return "$years year${years == 1 ? '' : 's'} ago";
      }
    } else {
      // 🔹 Türkçe biçimi
      if (difference.inSeconds < 60) {
        return "az önce";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes} dakika önce";
      } else if (difference.inHours < 24) {
        return "${difference.inHours} saat önce";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} gün önce";
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return "$weeks hafta önce";
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return "$months ay önce";
      } else {
        final years = (difference.inDays / 365).floor();
        return "$years yıl önce";
      }
    }
  }
}

