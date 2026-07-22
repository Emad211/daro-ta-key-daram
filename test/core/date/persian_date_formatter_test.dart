import 'package:daro_ta_key_daram/core/date/persian_date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats known Gregorian dates as Jalali with Persian digits', () {
    expect(
      PersianDateFormatter.date(DateTime(2024, 3, 20, 12)),
      '۱۴۰۳/۰۱/۰۱',
    );
    expect(
      PersianDateFormatter.date(DateTime(2025, 3, 21, 12)),
      '۱۴۰۴/۰۱/۰۱',
    );
  });

  test('formats Jalali date and 24-hour time consistently', () {
    expect(
      PersianDateFormatter.dateTime(DateTime(2025, 3, 21, 9, 5)),
      '۱۴۰۴/۰۱/۰۱ • ۰۹:۰۵',
    );
  });
}
