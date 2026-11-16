import 'package:flutter/material.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import '../domain/legal_consent_model.dart';

class IndiaLegalConsentDialog extends StatefulWidget {
  final Function(LegalConsentModel consent) onConsentGranted;
  final String? userId;

  const IndiaLegalConsentDialog({
    super.key,
    required this.onConsentGranted,
    this.userId,
  });

  @override
  State<IndiaLegalConsentDialog> createState() => _IndiaLegalConsentDialogState();
}

class _IndiaLegalConsentDialogState extends State<IndiaLegalConsentDialog> {
  bool _agreeTerms = false;
  bool _agreeKycVault = true;
  bool _agreeBillTracking = true;
  final bool _agreeWarrantyAlerts = true;
  bool _agreeOfflineSync = true;

  @override
  Widget build(BuildContext context) {
    final canProceed = _agreeTerms && _agreeKycVault;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ApnaColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ApnaColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.gavel_rounded, color: ApnaColors.accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Privacy & Legal Consent Notice', style: ApnaTypography.headingSmall),
                        Text(
                          'Compliant with Digital Personal Data Protection Act, 2023 (India)',
                          style: ApnaTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Apna is designed as a secure private and family workspace. In compliance with the DPDP Act 2023 and IT SPDI Rules 2011, we request your explicit, itemized consent to process and encrypt your personal documents, bills, and reminders.',
                style: ApnaTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ApnaColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ApnaColors.border),
                ),
                child: Column(
                  children: [
                    _buildCheckRow(
                      title: 'Identity & KYC Document Vault',
                      subtitle: 'Store masked Aadhaar, Passports, and PAN cards locally and in private cloud.',
                      value: _agreeKycVault,
                      onChanged: (val) => setState(() => _agreeKycVault = val ?? false),
                    ),
                    const Divider(height: 16),
                    _buildCheckRow(
                      title: 'Utility Bill Tracking & UPI Redirection',
                      subtitle: 'Keep track of electricity, water, internet due dates & open native UPI apps.',
                      value: _agreeBillTracking,
                      onChanged: (val) => setState(() => _agreeBillTracking = val ?? false),
                    ),
                    const Divider(height: 16),
                    _buildCheckRow(
                      title: 'Offline Encrypted Synchronization',
                      subtitle: 'Store encrypted local copy on device and sync across authorized family members.',
                      value: _agreeOfflineSync,
                      onChanged: (val) => setState(() => _agreeOfflineSync = val ?? false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreeTerms,
                    activeColor: ApnaColors.accent,
                    onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text.rich(
                        TextSpan(
                          text: 'I have read and affirmatively accept the ',
                          style: ApnaTypography.bodySmall.copyWith(color: ApnaColors.textPrimary),
                          children: const [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(color: ApnaColors.blue, fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'DPDP Privacy Policy',
                              style: TextStyle(color: ApnaColors.blue, fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: '. I understand my statutory right to withdraw consent or request data erasure at any time.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: canProceed
                        ? () {
                            final consent = LegalConsentModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              userId: widget.userId ?? 'user-default',
                              termsVersion: 'v1.0.0-2026',
                              privacyVersion: 'v1.0.0-2026',
                              consentPurposes: {
                                'identity_kyc_vault': _agreeKycVault,
                                'utility_bill_tracking': _agreeBillTracking,
                                'warranty_alerts': _agreeWarrantyAlerts,
                                'offline_sync': _agreeOfflineSync,
                              },
                              consentedAt: DateTime.now(),
                            );
                            widget.onConsentGranted(consent);
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ApnaColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Accept & Proceed to Workspace', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          activeColor: ApnaColors.accent,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ApnaTypography.titleMedium.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: ApnaTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
