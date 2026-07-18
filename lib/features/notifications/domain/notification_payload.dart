import 'dart:convert';

final class NotificationPayload {
  const NotificationPayload({
    required this.medicationId,
    this.version = currentVersion,
  });

  static const int currentVersion = 1;
  static const String _type = 'medication';

  final int version;
  final String medicationId;

  String get route => '/medications/${Uri.encodeComponent(medicationId)}';

  String encode() {
    if (medicationId.trim().isEmpty) {
      throw StateError('Notification medication id cannot be empty.');
    }

    return jsonEncode(<String, Object>{
      'v': version,
      'type': _type,
      'medicationId': medicationId,
    });
  }

  static NotificationPayload? tryDecode(String? encoded) {
    if (encoded == null || encoded.trim().isEmpty) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final Object? version = decoded['v'];
      final Object? type = decoded['type'];
      final Object? medicationId = decoded['medicationId'];
      if (version != currentVersion ||
          type != _type ||
          medicationId is! String ||
          medicationId.trim().isEmpty) {
        return null;
      }

      return NotificationPayload(medicationId: medicationId);
    } on FormatException {
      return null;
    }
  }
}
