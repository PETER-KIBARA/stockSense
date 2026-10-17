import 'package:intl/intl.dart';

/// Single place that decides how money is shown. Change [code] and [prefix] to switch currency.
class AppCurrency {
  static const String code = 'KES';
  static const String prefix = 'KES ';

  /// 1450 -> "KES 1,450", 1450.5 -> "KES 1,450.50"
  static String format(num value) {
    final isWhole = value == value.roundToDouble();
    final formatter = NumberFormat(isWhole ? '#,##0' : '#,##0.00');
    return '$prefix${formatter.format(value)}';
  }
}
