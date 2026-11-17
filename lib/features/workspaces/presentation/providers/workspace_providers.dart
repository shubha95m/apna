import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/workspace_remote_datasource.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/entities/workspace_member_entity.dart';

final workspaceRemoteDataSourceProvider = Provider<WorkspaceRemoteDataSource>((ref) {
  return WorkspaceRemoteDataSourceImpl();
});

/// Fetches all active workspaces where the authenticated user is a member/owner
final userWorkspacesProvider = FutureProvider<List<WorkspaceEntity>>((ref) async {
  final dataSource = ref.watch(workspaceRemoteDataSourceProvider);
  return await dataSource.getUserWorkspaces();
});

/// Explicit workspace override chosen by the user
final selectedWorkspaceIdProvider = StateProvider<String?>((ref) => null);

/// Currently active workspace entity, dynamically resolved
final activeWorkspaceProvider = Provider<WorkspaceEntity?>((ref) {
  final workspacesAsync = ref.watch(userWorkspacesProvider);
  final selectedId = ref.watch(selectedWorkspaceIdProvider);

  return workspacesAsync.maybeWhen(
    data: (workspaces) {
      if (workspaces.isEmpty) return null;

      // 1. If user explicitly selected a workspace, find it
      if (selectedId != null) {
        final match = workspaces.where((w) => w.id == selectedId).firstOrNull;
        if (match != null) return match;
      }

      // 2. Default to user's Family workspace if available
      final familyWorkspace = workspaces.where((w) => w.isFamily).firstOrNull;
      if (familyWorkspace != null) return familyWorkspace;

      // 3. Fallback to first available workspace
      return workspaces.first;
    },
    orElse: () => null,
  );
});

/// Dynamic active workspace ID for all repository queries
final activeWorkspaceIdProvider = Provider<String>((ref) {
  final active = ref.watch(activeWorkspaceProvider);
  return active?.id ?? '';
});

/// Dynamic workspace display name ('Personal' or 'Family')
final activeWorkspaceNameProvider = Provider<String>((ref) {
  final active = ref.watch(activeWorkspaceProvider);
  return active?.type == 'personal' ? 'Personal' : 'Family';
});

/// Current user's role in the active workspace ('owner', 'admin', 'writer', 'viewer')
final activeWorkspaceRoleProvider = Provider<String>((ref) {
  final active = ref.watch(activeWorkspaceProvider);
  return active?.userRole ?? 'owner';
});

/// Whether current user can add, edit, or delete items in the active workspace
final canWriteCurrentWorkspaceProvider = Provider<bool>((ref) {
  final active = ref.watch(activeWorkspaceProvider);
  if (active == null) return true;
  return active.canWrite;
});

/// Whether current user can manage members (owner or admin)
final canManageCurrentWorkspaceProvider = Provider<bool>((ref) {
  final active = ref.watch(activeWorkspaceProvider);
  if (active == null) return true;
  return active.isAdmin;
});

/// Workspace members directory for the given workspace ID
final workspaceMembersProvider =
    FutureProvider.family<List<WorkspaceMemberEntity>, String>((ref, workspaceId) async {
  if (workspaceId.isEmpty) return [];
  final dataSource = ref.watch(workspaceRemoteDataSourceProvider);
  return await dataSource.getWorkspaceMembers(workspaceId);
});
