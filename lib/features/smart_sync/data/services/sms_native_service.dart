import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:apna/app/theme/app_colors.dart';

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

  /// Checks and requests SMS permission, or shows an interactive dialog directing the user to Settings.
  static Future<bool> ensureSmsPermissionOrPrompt(BuildContext context) async {
    if (!isSupportedPlatform) return true;

    // 1. Check if already granted
    bool granted = await hasPermission();
    if (granted) return true;

    // 2. Try requesting runtime permission via permission_handler
    final status = await Permission.sms.request();
    if (status.isGranted) return true;

    // 3. Fallback to native MethodChannel request
    granted = await requestPermission();
    if (granted) return true;

    // 4. If denied or permanently denied, prompt user to go to Settings
    if (!context.mounted) return false;

    final openSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sms_failed_rounded, color: ApnaColors.warning, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'SMS Permission Needed',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Because this APK was downloaded directly (outside the Google Play Store), Android 13/14/15 places SMS under "Restricted Settings".',
              style: TextStyle(fontSize: 13, height: 1.4, color: ApnaColors.textSecondary),
            ),
            SizedBox(height: 10),
            Text(
              'Quick 10-Second Unlock:\n'
              '1. Tap "Open Settings" below.\n'
              '2. Tap the 3 dots (⋮) in the top-right corner.\n'
              '3. Select "Allow restricted settings" & enter PIN/fingerprint.\n'
              '4. Tap Permissions ➔ SMS ➔ Allow.',
              style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: ApnaColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ApnaColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (openSettings == true) {
      await openAppSettings();
    }
    return false;
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
