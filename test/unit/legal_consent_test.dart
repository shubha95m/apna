import 'package:flutter_test/flutter_test.dart';
import 'package:apna/features/legal_consent/domain/legal_consent_model.dart';

void main() {
  test('LegalConsentModel accurately evaluates DPDP Act compliance status', () {
    final validConsent = LegalConsentModel(
      id: 'consent-1',
      userId: 'user-shubham',
      termsVersion: 'v1.0.0-2026',
      privacyVersion: 'v1.0.0-2026',
      consentPurposes: {
        'identity_kyc_vault': true,
        'utility_bill_tracking': true,
        'offline_sync': true,
      },
      consentedAt: DateTime.now(),
    );

    expect(validConsent.isCompliant, isTrue);

    final revokedConsent = LegalConsentModel(
      id: 'consent-2',
      userId: 'user-shubham',
      termsVersion: 'v1.0.0-2026',
      privacyVersion: 'v1.0.0-2026',
      consentPurposes: {
        'identity_kyc_vault': true,
        'utility_bill_tracking': true,
      },
      consentedAt: DateTime.now().subtract(const Duration(days: 10)),
      revokedAt: DateTime.now(),
    );

    expect(revokedConsent.isCompliant, isFalse);
  });
}

