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
  bool _smsPermission = true;
  bool _notificationPermission = true;
  bool _cameraPermission = true;
  bool _isRequesting = false;

  Future<void> _handleGrantPermissions() async {
    setState(() => _isRequesting = true);

    try {
      if (!kIsWeb) {
        if (_smsPermission) {
          await Permission.sms.request();
        }
        if (_notificationPermission) {
          await Permission.notification.request();
        }
        if (_cameraPermission) {
          await Permission.camera.request();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('apna_permissions_requested', true);
      await prefs.setBool('apna_sms_sync_enabled', _smsPermission);
      await prefs.setBool('apna_notifications_enabled', _notificationPermission);
      await prefs.setBool('apna_camera_enabled', _cameraPermission);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Smart Auto-Sync enabled! Apna will automatically track upcoming bills & due dates.'),
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
              'In compliance with DPDP Act 2023, Apna processes financial notifications and messages on-device to auto-populate your workspace with zero manual effort:',
              style: ApnaTypography.bodyMedium,
            ),
            const SizedBox(height: 18),

            // Permission Item 1: SMS / Messaging
            _buildPermissionTile(
              icon: Icons.sms_outlined,
              title: 'Auto-Read Utility Bills & Bank SMS',
              subtitle: 'Reads incoming SMS from electricity, water, gas, broadband & bank cards to populate bills and due dates.',
              value: _smsPermission,
              onChanged: (val) => setState(() => _smsPermission = val),
            ),
            const SizedBox(height: 12),

            // Permission Item 2: Notifications
            _buildPermissionTile(
              icon: Icons.notifications_active_outlined,
              title: 'Timely Due Date & Warranty Alerts',
              subtitle: 'Notifies you 3 days and 1 day prior to bill due dates and appliance warranty expirations.',
              value: _notificationPermission,
              onChanged: (val) => setState(() => _notificationPermission = val),
            ),
            const SizedBox(height: 12),

            // Permission Item 3: Camera & Receipts
            _buildPermissionTile(
              icon: Icons.document_scanner_outlined,
              title: 'Receipt & Warranty Card Scanner',
              subtitle: 'Allows photographing paper bills, retail receipts, and equipment serial stickers to attach directly to records.',
              value: _cameraPermission,
              onChanged: (val) => setState(() => _cameraPermission = val),
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
