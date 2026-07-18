import 'dart:convert';

abstract final class NotificationId {
  static const int _fnvOffsetBasis = 0x811C9DC5;
  static const int _fnvPrime = 0x01000193;
  static const int _uint32Mask = 0xFFFFFFFF;
  static const int _positiveInt31Mask = 0x7FFFFFFF;

  static int forMedication(String medicationId) {
    final String normalized = medicationId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        medicationId,
        'medicationId',
        'Medication id cannot be empty.',
      );
    }

    int hash = _fnvOffsetBasis;
    for (final int byte in utf8.encode(normalized)) {
      hash ^= byte;
      hash = (hash * _fnvPrime) & _uint32Mask;
    }

    final int positive = hash & _positiveInt31Mask;
    return positive == 0 ? 1 : positive;
  }
}
