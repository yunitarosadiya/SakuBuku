import 'package:intl/intl.dart';

class DateFormatter {
  /// Format: "Senin, 3 Nov 2026"
  static String formatFull(DateTime date) {
    try {
      return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('EEEE, d MMM yyyy').format(date);
    }
  }

  /// Format: "3 November 2026"
  static String formatMedium(DateTime date) {
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  /// Format: "03/11/2026"
  static String formatShort(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  /// Format month & year: "November 2026"
  static String formatMonthYear(DateTime date) {
    try {
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('MMMM yyyy').format(date);
    }
  }

  /// Format relative day: "Hari ini", "Kemarin", or "d MMM"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diff = today.difference(target).inDays;
    if (diff == 0) {
      return 'Hari ini';
    } else if (diff == 1) {
      return 'Kemarin';
    } else {
      try {
        return DateFormat('d MMM yyyy', 'id_ID').format(date);
      } catch (_) {
        return DateFormat('d MMM yyyy').format(date);
      }
    }
  }

  /// Format time: "14:30"
  static String formatTime(DateTime date) {
    try {
      return DateFormat('HH:mm', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('HH:mm').format(date);
    }
  }
}
