import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../data/services/smart_sync_service.dart';

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
      );
      state = AsyncValue.data(res);
      return res;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}
