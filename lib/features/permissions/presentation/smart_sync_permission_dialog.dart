import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';

class SmartSyncPermissionDialog extends StatefulWidget {
  const SmartSyncPermissionDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool('apna_permissions_requested') ?? false;
    if (!alreadyRequested && context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const SmartSyncPermissionDialog(),
      );
    }
  }

  @override
  State<SmartSyncPermissionDialog> createState() => _SmartSyncPermissionDialogState();
}

class _SmartSyncPermissionDialogState extends State<SmartSyncPermissionDialog> {
  bool _notificationPermission = true;
  bool _cameraPermission = true;
  bool _storagePermission = true;
  bool _isRequesting = false;

  Future<void> _handleGrantPermissions() async {
    setState(() => _isRequesting = true);

    try {
      if (!kIsWeb) {
        if (_notificationPermission) {
          await Permission.notification.request();
        }
        if (_cameraPermission) {
          await Permission.camera.request();
        }
        if (_storagePermission) {
          await Permission.photos.request();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('apna_permissions_requested', true);
      await prefs.setBool('apna_notifications_enabled', _notificationPermission);
      await prefs.setBool('apna_camera_enabled', _cameraPermission);
      await prefs.setBool('apna_storage_enabled', _storagePermission);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissions saved! Apna is ready to scan documents, send due alerts, and protect your family records.'),
            backgroundColor: ApnaColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('apna_permissions_requested', true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ApnaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: ApnaColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ApnaColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: ApnaColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smart Bill & Financial Sync', style: ApnaTypography.headingSmall),
                      SizedBox(height: 2),
                      Text(
                        'Automate tracking for family bills and payments',
                        style: ApnaTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'In compliance with DPDP Act 2023 & Google Play Protect guidelines, Apna only requests official device capabilities needed to organize your household documents and bills:',
              style: ApnaTypography.bodyMedium,
            ),
            const SizedBox(height: 18),

            // Permission Item 1: Camera
            _buildPermissionTile(
              icon: Icons.document_scanner_outlined,
              title: 'Camera Document & Receipt Scanner',
              subtitle: 'Allows photographing paper bills, retail receipts, warranty cards, and KYC documents to attach directly to records.',
              value: _cameraPermission,
              onChanged: (val) => setState(() => _cameraPermission = val),
            ),
            const SizedBox(height: 12),

            // Permission Item 2: Notifications
            _buildPermissionTile(
              icon: Icons.notifications_active_outlined,
              title: 'Timely Due Date & Warranty Alerts',
              subtitle: 'Notifies you prior to utility bill due dates, policy renewals, and appliance warranty expirations.',
              value: _notificationPermission,
              onChanged: (val) => setState(() => _notificationPermission = val),
            ),
            const SizedBox(height: 12),

            // Permission Item 3: Photos & Files
            _buildPermissionTile(
              icon: Icons.photo_library_outlined,
              title: 'Document & PDF Import Access',
              subtitle: 'Select PDF statements, receipts, and warranty files from device storage to securely encrypt in your vault.',
              value: _storagePermission,
              onChanged: (val) => setState(() => _storagePermission = val),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isRequesting ? null : _handleGrantPermissions,
                icon: _isRequesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text(
                  'Grant Permissions & Enable Auto-Sync',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ApnaColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _isRequesting ? null : _handleSkip,
                child: const Text(
                  'I will enter details manually (Skip)',
                  style: TextStyle(color: ApnaColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ApnaColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ApnaColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ApnaColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ApnaColors.border),
            ),
            child: Icon(icon, size: 20, color: ApnaColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: ApnaColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: ApnaColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
