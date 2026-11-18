class RawSmsMessage {
  final String id;
  final String address;
  final String body;
  final DateTime date;

  const RawSmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
  });

  factory RawSmsMessage.fromMap(Map<dynamic, dynamic> map) {
    final dateMs = (map['date'] as num?)?.toInt() ?? 0;
    return RawSmsMessage(
      id: map['id']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(dateMs),
    );
  }
}

class SmsNativeService {
  /// SMS reading permission is intentionally disabled in the Android Manifest
  /// to prevent Google Play Protect from blocking sideloaded APK installations
  /// for "risk of financial fraud or identity theft".
  static bool get isSupportedPlatform => false;

  static Future<bool> hasPermission() async => false;

  static Future<bool> requestPermission() async => false;

  static Future<List<RawSmsMessage>> getRecentSms({int days = 30, int maxCount = 200}) async => [];
}
