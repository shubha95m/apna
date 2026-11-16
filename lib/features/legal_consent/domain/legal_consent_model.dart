class LegalConsentModel {
  final String id;
  final String userId;
  final String termsVersion;
  final String privacyVersion;
  final Map<String, bool> consentPurposes;
  final String? deviceId;
  final DateTime consentedAt;
  final DateTime? revokedAt;

  const LegalConsentModel({
    required this.id,
    required this.userId,
    required this.termsVersion,
    required this.privacyVersion,
    required this.consentPurposes,
    this.deviceId,
    required this.consentedAt,
    this.revokedAt,
  });

  bool get isCompliant =>
      revokedAt == null &&
      (consentPurposes['identity_kyc_vault'] ?? false) &&
      (consentPurposes['utility_bill_tracking'] ?? false);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'terms_version': termsVersion,
      'privacy_version': privacyVersion,
      'consent_purposes': consentPurposes.toString(),
      'device_id': deviceId,
      'consented_at': consentedAt.toIso8601String(),
      'revoked_at': revokedAt?.toIso8601String(),
    };
  }
}

