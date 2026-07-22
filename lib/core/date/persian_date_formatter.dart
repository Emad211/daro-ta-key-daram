import 'package:persian_datetime_picker/persian_datetime_picker.dart';

abstract final class PersianDateFormatter {
  static String date(DateTime value) {
    final Jalali jalali = Jalali.fromDateTime(value.toLocal());
    return _persianDigits(
      '${jalali.year}/${_twoDigits(jalali.month)}/${_twoDigits(jalali.day)}',
    );
  }

  static String time(DateTime value) {
    final DateTime local = value.toLocal();
    return _persianDigits(
      '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}',
    );
  }

  static String dateTime(DateTime value) {
    return '${date(value)} • ${time(value)}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static String _persianDigits(String value) {
    const String latinDigits = '0123456789';
    const String persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    return value.split('').map((String character) {
      final int index = latinDigits.indexOf(character);
      return index < 0 ? character : persianDigits[index];
    }).join();
  }
}
