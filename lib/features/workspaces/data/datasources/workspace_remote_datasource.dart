import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/configuration/supabase_config.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/entities/workspace_member_entity.dart';

abstract interface class WorkspaceRemoteDataSource {
  Future<List<WorkspaceEntity>> getUserWorkspaces();
  Future<List<WorkspaceMemberEntity>> getWorkspaceMembers(String workspaceId);
  Future<void> inviteMember({
    required String workspaceId,
    required String email,
    required String role,
  });
  Future<void> updateMemberRole({
    required String workspaceId,
    required String userId,
    required String role,
  });
  Future<void> removeMember({
    required String workspaceId,
    required String userId,
  });
}

class WorkspaceRemoteDataSourceImpl implements WorkspaceRemoteDataSource {
  @override
  Future<List<WorkspaceEntity>> getUserWorkspaces() async {
    if (!SupabaseConfig.isConfigured) return [];
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await client
        .from('workspaces')
        .select('id, name, type, owner_id, created_at, workspace_members!inner(role, user_id)')
        .eq('workspace_members.user_id', currentUserId)
        .isFilter('deleted_at', null)
        .order('type', ascending: false);

    return (response as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      return WorkspaceEntity.fromJson(map);
    }).toList();
  }

  @override
  Future<List<WorkspaceMemberEntity>> getWorkspaceMembers(String workspaceId) async {
    if (!SupabaseConfig.isConfigured) return [];
    final client = Supabase.instance.client;

    final response = await client.rpc(
      'get_workspace_members_detail',
      params: {'p_workspace_id': workspaceId},
    );

    return (response as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      return WorkspaceMemberEntity.fromJson(map);
    }).toList();
  }

  @override
  Future<void> inviteMember({
    required String workspaceId,
    required String email,
    required String role,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    final client = Supabase.instance.client;

    await client.rpc(
      'invite_workspace_member',
      params: {
        'p_workspace_id': workspaceId,
        'p_email': email.trim().toLowerCase(),
        'p_role': role.trim().toLowerCase(),
      },
    );
  }

  @override
  Future<void> updateMemberRole({
    required String workspaceId,
    required String userId,
    required String role,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    final client = Supabase.instance.client;

    await client.rpc(
      'update_workspace_member_role',
      params: {
        'p_workspace_id': workspaceId,
        'p_user_id': userId,
        'p_role': role.trim().toLowerCase(),
      },
    );
  }

  @override
  Future<void> removeMember({
    required String workspaceId,
    required String userId,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    final client = Supabase.instance.client;

    await client.rpc(
      'remove_workspace_member',
      params: {
        'p_workspace_id': workspaceId,
        'p_user_id': userId,
      },
    );
  }
}
