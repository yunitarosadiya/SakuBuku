import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  /// Format double to "Rp 150.000"
  static String formatRupiah(num amount) {
    return _rupiahFormat.format(amount);
  }

  /// Format compact: "Rp 1,5 Jt"
  static String formatCompact(num amount) {
    return _compactFormat.format(amount);
  }

  /// Format with sign: "+Rp 150.000" or "-Rp 50.000"
  static String formatWithSign(num amount, String type) {
    final formatted = formatRupiah(amount.abs());
    if (type.toUpperCase() == 'INCOME') {
      return '+$formatted';
    } else {
      return '-$formatted';
    }
  }

  /// Parse user raw string "150000" to num
  static double parseRaw(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
}
