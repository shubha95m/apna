import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../data/services/smart_sync_service.dart';
import '../../data/services/sms_native_service.dart';

final smartSyncControllerProvider = StateNotifierProvider<SmartSyncController, AsyncValue<SmartSyncResult?>>((ref) {
  return SmartSyncController(ref);
});

class SmartSyncController extends StateNotifier<AsyncValue<SmartSyncResult?>> {
  final Ref _ref;

  SmartSyncController(this._ref) : super(const AsyncValue.data(null));

  Future<SmartSyncResult?> runInitialSyncIfNeeded() async {
    final user = _ref.read(authControllerProvider).valueOrNull;
    final workspace = _ref.read(activeWorkspaceProvider);
    if (user == null || workspace == null) return null;

    try {
      final res = await SmartSyncService.syncInitialMonthIfNeeded(
        workspaceId: workspace.id,
        userId: user.id,
      );
      if (res != null) {
        state = AsyncValue.data(res);
      }
      return res;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Syncs real SMS from Android device inbox
  Future<SmartSyncResult?> runDeviceSmsSync() async {
    final user = _ref.read(authControllerProvider).valueOrNull;
    final workspace = _ref.read(activeWorkspaceProvider);
    if (user == null || workspace == null) return null;

    state = const AsyncValue.loading();
    try {
      if (SmsNativeService.isSupportedPlatform) {
        final hasPerm = await SmsNativeService.hasPermission();
        if (!hasPerm) {
          final granted = await SmsNativeService.requestPermission();
          if (!granted) {
            const deniedRes = SmartSyncResult(
              billsImported: 0,
              expensesImported: 0,
              warrantiesImported: 0,
              calendarEventsImported: 0,
              duplicatesSkipped: 0,
              message: 'SMS permission is required to read bank and utility messages.',
            );
            state = const AsyncValue.data(deniedRes);
            return deniedRes;
          }
        }
      }

      final res = await SmartSyncService.syncLastMonth(
        workspaceId: workspace.id,
        userId: user.id,
        fetchFromDeviceSms: true,
        fetchFromGmail: false,
      );
      state = AsyncValue.data(res);
      return res;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Syncs emails from Gmail
  Future<SmartSyncResult?> runGmailSync() async {
    final user = _ref.read(authControllerProvider).valueOrNull;
    final workspace = _ref.read(activeWorkspaceProvider);
    if (user == null || workspace == null) return null;

    state = const AsyncValue.loading();
    try {
      final res = await SmartSyncService.syncLastMonth(
        workspaceId: workspace.id,
        userId: user.id,
        fetchFromDeviceSms: false,
        fetchFromGmail: true,
      );
      state = AsyncValue.data(res);
      return res;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Parses user-pasted statements or raw message texts
  Future<SmartSyncResult?> runManualSync({List<String>? customMessages}) async {
    final user = _ref.read(authControllerProvider).valueOrNull;
    final workspace = _ref.read(activeWorkspaceProvider);
    if (user == null || workspace == null) return null;

    state = const AsyncValue.loading();
    try {
      final res = await SmartSyncService.syncLastMonth(
        workspaceId: workspace.id,
        userId: user.id,
        customMessages: customMessages,
        fetchFromDeviceSms: customMessages == null,
      );
      state = AsyncValue.data(res);
      return res;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}
