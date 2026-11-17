import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/workspace_entity.dart';
import '../../domain/entities/workspace_member_entity.dart';
import '../providers/workspace_providers.dart';

class ManageFamilyMembersDialog extends ConsumerStatefulWidget {
  final WorkspaceEntity workspace;

  const ManageFamilyMembersDialog({
    super.key,
    required this.workspace,
  });

  static Future<void> show(BuildContext context, WorkspaceEntity workspace) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ManageFamilyMembersDialog(workspace: workspace),
    );
  }

  @override
  ConsumerState<ManageFamilyMembersDialog> createState() => _ManageFamilyMembersDialogState();
}

class _ManageFamilyMembersDialogState extends ConsumerState<ManageFamilyMembersDialog> {
  final _emailController = TextEditingController();
  String _selectedRole = 'writer';
  bool _isSubmitting = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _isError = true;
        _statusMessage = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    try {
      final dataSource = ref.read(workspaceRemoteDataSourceProvider);
      await dataSource.inviteMember(
        workspaceId: widget.workspace.id,
        email: email,
        role: _selectedRole,
      );

      _emailController.clear();
      setState(() {
        _isError = false;
        _statusMessage = 'Member added successfully with $_selectedRole access.';
      });
      ref.invalidate(workspaceMembersProvider(widget.workspace.id));
    } catch (e) {
      final errStr = e.toString();
      String msg = 'Failed to invite member';
      if (errStr.contains('not registered yet')) {
        msg = 'User with email "$email" has not registered yet. Please have them create an Apna account first.';
      } else if (errStr.contains('Access denied')) {
        msg = 'Only workspace Admins or Owners can invite new members.';
      } else {
        msg = errStr.replaceAll('Exception: ', '').replaceAll('PostgrestException(message: ', '').replaceAll(')', '');
      }
      setState(() {
        _isError = true;
        _statusMessage = msg;
      });
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleRoleChange(WorkspaceMemberEntity member, String newRole) async {
    try {
      final dataSource = ref.read(workspaceRemoteDataSourceProvider);
      await dataSource.updateMemberRole(
        workspaceId: widget.workspace.id,
        userId: member.userId,
        role: newRole,
      );
      ref.invalidate(workspaceMembersProvider(widget.workspace.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${member.displayName} role to $newRole'),
            backgroundColor: ApnaColors.accentDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            backgroundColor: ApnaColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRemoveMember(WorkspaceMemberEntity member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Family Member?'),
        content: Text('Are you sure you want to remove ${member.displayName} (${member.email}) from this family workspace? They will lose access to all family documents.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: ApnaColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dataSource = ref.read(workspaceRemoteDataSourceProvider);
      await dataSource.removeMember(
        workspaceId: widget.workspace.id,
        userId: member.userId,
      );
      ref.invalidate(workspaceMembersProvider(widget.workspace.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${member.displayName} from family workspace'),
            backgroundColor: ApnaColors.accentDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: ApnaColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(workspaceMembersProvider(widget.workspace.id));
    final canManage = widget.workspace.isAdmin;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ApnaColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ApnaColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.group_outlined, color: ApnaColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.workspace.name} Workspace Members',
                          style: ApnaTypography.headingMedium.copyWith(fontSize: 18),
                        ),
                        Text(
                          canManage
                              ? 'Manage members, invite family by email, and assign roles'
                              : 'Members directory (Read-only access)',
                          style: ApnaTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Invite Member Section (Only for Admin / Owner)
              if (canManage) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ApnaColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ApnaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invite Family Member',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'family.member@gmail.com',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.email_outlined, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              isDense: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'writer', child: Text('Writer (Edit)')),
                                DropdownMenuItem(value: 'read_only', child: Text('Viewer (Read)')),
                                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedRole = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _handleInvite,
                            style: FilledButton.styleFrom(
                              backgroundColor: ApnaColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Invite', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              _isError ? Icons.error_outline : Icons.check_circle_outline,
                              size: 16,
                              color: _isError ? ApnaColors.error : ApnaColors.accentDark,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isError ? ApnaColors.error : ApnaColors.accentDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Role Legend Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ApnaColors.surfaceSubtle.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: ApnaColors.textSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Owner/Admin: Full control • Writer: Add/Edit/Delete records • Viewer: View & download only',
                        style: TextStyle(fontSize: 11, color: ApnaColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Members List
              Expanded(
                child: membersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('Error loading members: $err', style: const TextStyle(color: ApnaColors.error)),
                  ),
                  data: (members) {
                    if (members.isEmpty) {
                      return const Center(
                        child: Text('No members found in this workspace.'),
                      );
                    }

                    return ListView.separated(
                      itemCount: members.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: member.isOwner ? ApnaColors.primary : ApnaColors.border,
                            child: Text(
                              member.initials,
                              style: TextStyle(
                                color: member.isOwner ? Colors.white : ApnaColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  member.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildRoleBadge(member.role, member.isOwner),
                            ],
                          ),
                          subtitle: Text(
                            member.email,
                            style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary),
                          ),
                          trailing: canManage && !member.isOwner
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Dropdown to update role
                                    DropdownButton<String>(
                                      value: (member.role == 'owner')
                                          ? 'admin'
                                          : (member.role == 'member' ? 'writer' : member.role),
                                      underline: const SizedBox(),
                                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                                      style: const TextStyle(fontSize: 12, color: ApnaColors.textPrimary),
                                      items: const [
                                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                        DropdownMenuItem(value: 'writer', child: Text('Writer')),
                                        DropdownMenuItem(value: 'read_only', child: Text('Viewer')),
                                      ],
                                      onChanged: (newRole) {
                                        if (newRole != null && newRole != member.role) {
                                          _handleRoleChange(member, newRole);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    // Remove button
                                    IconButton(
                                      icon: const Icon(Icons.person_remove_outlined, size: 18, color: ApnaColors.error),
                                      tooltip: 'Remove from workspace',
                                      onPressed: () => _handleRemoveMember(member),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, bool isOwner) {
    Color bg;
    Color text;
    String label;

    if (isOwner || role == 'owner') {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFF92400E);
      label = 'Owner';
    } else if (role == 'admin') {
      bg = const Color(0xFFE0E7FF);
      text = const Color(0xFF3730A3);
      label = 'Admin';
    } else if (role == 'writer' || role == 'member') {
      bg = const Color(0xFFD1FAE5);
      text = const Color(0xFF065F46);
      label = 'Writer';
    } else {
      bg = const Color(0xFFF3F4F6);
      text = const Color(0xFF4B5563);
      label = 'Viewer';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
