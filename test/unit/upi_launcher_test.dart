import 'package:flutter_test/flutter_test.dart';
import 'package:apna/core/integrations/upi_launcher.dart';

void main() {
  test('UpiPaymentRequest generates compliant NPCI UPI intent URI', () {
    const req = UpiPaymentRequest(
      payeeVpa: 'tneb@billpay',
      payeeName: 'TNEB Electricity',
      amount: 1850.0,
      transactionNote: 'Apna Electricity Bill',
      transactionRef: 'APNA-12345',
    );

    final genericUri = req.toUri(UpiApp.generic);
    expect(genericUri.scheme, equals('upi'));
    expect(genericUri.host, equals('pay'));
    expect(genericUri.queryParameters['pa'], equals('tneb@billpay'));
    expect(genericUri.queryParameters['am'], equals('1850.00'));
    expect(genericUri.queryParameters['cu'], equals('INR'));

    final gpayUri = req.toUri(UpiApp.googlePay);
    expect(gpayUri.scheme, equals('gpay'));

    final phonePeUri = req.toUri(UpiApp.phonePe);
    expect(phonePeUri.scheme, equals('phonepe'));

    final paytmUri = req.toUri(UpiApp.paytm);
    expect(paytmUri.scheme, equals('paytmmp'));
  });
}

