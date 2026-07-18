abstract final class LocalizedNumberParser {
  static const String _persianDigits = '۰۱۲۳۴۵۶۷۸۹';
  static const String _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

  static String normalize(String? value) {
    String normalized = (value ?? '')
        .trim()
        .replaceAll('٬', '')
        .replaceAll('٫', '.')
        .replaceAll('،', '.')
        .replaceAll(',', '.');

    for (int index = 0; index < 10; index += 1) {
      normalized = normalized
          .replaceAll(_persianDigits[index], '$index')
          .replaceAll(_arabicDigits[index], '$index');
    }
    return normalized;
  }

  static double? tryParseDouble(String? value) {
    return double.tryParse(normalize(value));
  }
}
