import 'package:easy_localization/easy_localization.dart';

//// Formatter to format dates.
final DateFormat formatter = DateFormat('yyyy-MM-dd');

/// Extension to allow basic functions used on [DateTime] used app-wide.
extension Time on DateTime {
  /// Converts [this] to [String] representation using [formatter].
  String format() => formatter.format(this);

  /// Converts [str] to [DateTime] using [formatter].
  static DateTime parse(String str) => formatter.parse(str);
}
