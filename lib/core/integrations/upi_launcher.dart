import 'package:url_launcher/url_launcher.dart';

enum UpiApp {
  generic,
  googlePay,
  phonePe,
  paytm,
  bhim,
}

class UpiPaymentRequest {
  final String payeeVpa;
  final String payeeName;
  final double amount;
  final String transactionNote;
  final String transactionRef;

  const UpiPaymentRequest({
    required this.payeeVpa,
    required this.payeeName,
    required this.amount,
    required this.transactionNote,
    required this.transactionRef,
  });

  Uri toUri([UpiApp app = UpiApp.generic]) {
    final queryParams = {
      'pa': payeeVpa,
      'pn': payeeName,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tn': transactionNote,
      'tr': transactionRef,
    };

    final scheme = switch (app) {
      UpiApp.googlePay => 'gpay://upi/pay',
      UpiApp.phonePe => 'phonepe://pay',
      UpiApp.paytm => 'paytmmp://pay',
      UpiApp.bhim => 'bhim://pay',
      UpiApp.generic => 'upi://pay',
    };

    return Uri.parse(scheme).replace(queryParameters: queryParams);
  }
}

class UpiLauncher {
  static Future<bool> launchUpiPayment(
    UpiPaymentRequest request, {
    UpiApp app = UpiApp.generic,
  }) async {
    final uri = request.toUri(app);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Fallback to generic upi:// intent if specific app is not installed
    if (app != UpiApp.generic) {
      final genericUri = request.toUri(UpiApp.generic);
      if (await canLaunchUrl(genericUri)) {
        return await launchUrl(genericUri, mode: LaunchMode.externalApplication);
      }
    }
    return false;
  }
}
