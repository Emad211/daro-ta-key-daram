import 'package:daro_ta_key_daram/core/input/localized_number_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalizedNumberParser', () {
    test('parses Persian digits and decimal separator', () {
      expect(LocalizedNumberParser.tryParseDouble('۱۲٫۵'), 12.5);
    });

    test('parses Arabic digits and comma decimal separator', () {
      expect(LocalizedNumberParser.tryParseDouble('١٠,٥'), 10.5);
    });

    test('removes Persian thousands separator', () {
      expect(LocalizedNumberParser.tryParseDouble('۱٬۲۵۰'), 1250);
    });

    test('returns null for non-numeric input', () {
      expect(LocalizedNumberParser.tryParseDouble('دوازده'), isNull);
    });
  });
}
