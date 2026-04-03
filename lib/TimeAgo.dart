import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TimeAgo {
  static String format(BuildContext context, DateTime date) {
    final loc = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final diff = now.difference(date);
    final locale = Localizations.localeOf(context).toString();

    // 🔴 Eğer farklı yıldaysa direkt tam tarih göster
    if (date.year != now.year) {
      return DateFormat('d MMMM y', locale).format(date);
      // örn: 2 Mart 2025
    }

    // 🟢 Aynı yılsa normal "time ago"
    if (diff.inSeconds < 60) {
      return loc.justNow;
    } else if (diff.inMinutes < 60) {
      return loc.minuteAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return loc.hourAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      return loc.dayAgo(diff.inDays);
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return loc.weekAgo(weeks);
    } else {
      // Aynı yıl ama 1 aydan fazla → sadece gün + ay
      return DateFormat('d MMMM', locale).format(date);
      // örn: 2 Mart
    }
  }
}


