import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TimeAgo {
  static String format(BuildContext context, DateTime date) {
    final loc = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final diff = now.difference(date);

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
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return loc.monthAgo(months);
    } else {
      final years = (diff.inDays / 365).floor();
      return loc.yearAgo(years);
    }
  }
}


