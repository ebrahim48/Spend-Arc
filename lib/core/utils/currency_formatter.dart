import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static String format(double amount) => _formatter.format(amount);

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }

  static String formatSigned(double amount) {
    final formatted = format(amount.abs());
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }
}

class DateFormatter {
  static final _dateFormat = DateFormat('MMM dd, yyyy');
  static final _monthFormat = DateFormat('MMMM yyyy');
  static final _shortFormat = DateFormat('MMM dd');
  static final _dayFormat = DateFormat('dd');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatMonth(DateTime date) => _monthFormat.format(date);
  static String formatShort(DateTime date) => _shortFormat.format(date);
  static String formatDay(DateTime date) => _dayFormat.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDate(date);
  }
}
