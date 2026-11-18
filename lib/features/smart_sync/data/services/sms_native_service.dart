import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  static const MethodChannel _channel = MethodChannel('com.apna.apna/sms_reader');

  /// Returns true if running on native Android device
  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Checks if READ_SMS permission is currently granted
  static Future<bool> hasPermission() async {
    if (!isSupportedPlatform) return false;
    try {
      final res = await _channel.invokeMethod<bool>('hasSmsPermission');
      return res ?? false;
    } catch (e) {
      debugPrint('Error checking SMS permission: $e');
      return false;
    }
  }

  /// Requests READ_SMS permission at runtime from the user
  static Future<bool> requestPermission() async {
    if (!isSupportedPlatform) return false;
    try {
      final res = await _channel.invokeMethod<bool>('requestSmsPermission');
      return res ?? false;
    } catch (e) {
      debugPrint('Error requesting SMS permission: $e');
      return false;
    }
  }

  /// Fetches real inbox SMS messages from the last [days] (default 30 days)
  static Future<List<RawSmsMessage>> getRecentSms({int days = 30, int maxCount = 200}) async {
    if (!isSupportedPlatform) return [];

    try {
      final sinceDate = DateTime.now().subtract(Duration(days: days));
      final rawList = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'getInboxSms',
        {
          'sinceMs': sinceDate.millisecondsSinceEpoch,
          'maxCount': maxCount,
        },
      );

      if (rawList == null) return [];

      final results = <RawSmsMessage>[];
      for (final item in rawList) {
        final sms = RawSmsMessage.fromMap(item);
        if (_isFinancialOrUtilitySms(sms)) {
          results.add(sms);
        }
      }
      return results;
    } catch (e) {
      debugPrint('Error reading device inbox SMS: $e');
      return [];
    }
  }

  /// Filters out personal chat and retains transactional, banking & utility SMS
  static bool _isFinancialOrUtilitySms(RawSmsMessage sms) {
    final body = sms.body.toLowerCase();
    final addr = sms.address.toUpperCase();

    // Known financial sender substrings
    final isKnownSender = addr.contains('HDFC') ||
        addr.contains('SBI') ||
        addr.contains('ICICI') ||
        addr.contains('AXIS') ||
        addr.contains('KOTAK') ||
        addr.contains('AIRTEL') ||
        addr.contains('JIO') ||
        addr.contains('BESCOM') ||
        addr.contains('TATA') ||
        addr.contains('AMAZON') ||
        addr.contains('SWIGGY') ||
        addr.contains('ZOMATO');
    final hasFinancialKeywords = body.contains('rs.') ||
        body.contains('rs ') ||
        body.contains('inr') ||
        body.contains('₹') ||
        body.contains('debited') ||
        body.contains('credited') ||
        body.contains('due date') ||
        body.contains('bill') ||
        body.contains('recharge') ||
        body.contains('warranty') ||
        body.contains('order delivered') ||
        body.contains('order confirmed') ||
        body.contains('statement') ||
        body.contains('invoice') ||
        body.contains('spent') ||
        body.contains('a/c') ||
        body.contains('vpa');

    if (!hasFinancialKeywords && !isKnownSender) return false;

    // Filter out obvious spam or OTP-only messages that have no amounts
    if (body.contains('otp is') || body.contains('verification code')) {
      // If it's ONLY an OTP with no debited/credited or bill due, skip
      if (!body.contains('debited') && !body.contains('bill') && !body.contains('due')) {
        return false;
      }
    }

    return true;
  }
}
