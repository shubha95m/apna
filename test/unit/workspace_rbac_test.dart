import 'package:flutter_test/flutter_test.dart';
import 'package:apna/features/workspaces/domain/entities/workspace_entity.dart';
import 'package:apna/features/workspaces/domain/entities/workspace_member_entity.dart';

void main() {
  group('WorkspaceEntity RBAC & Permissions', () {
    test('Owner has full write and admin privileges', () {
      final ws = WorkspaceEntity(
        id: 'ws-1',
        name: 'Sharma Family',
        type: 'family',
        ownerId: 'usr-1',
        userRole: 'owner',
        createdAt: DateTime.now(),
      );

      expect(ws.isOwner, isTrue);
      expect(ws.isAdmin, isTrue);
      expect(ws.canWrite, isTrue);
      expect(ws.isReadOnly, isFalse);
      expect(ws.isFamily, isTrue);
      expect(ws.isPersonal, isFalse);
    });

    test('Admin has write and manage permissions but is not owner', () {
      final ws = WorkspaceEntity(
        id: 'ws-2',
        name: 'Sharma Family',
        type: 'family',
        ownerId: 'usr-1',
        userRole: 'admin',
        createdAt: DateTime.now(),
      );

      expect(ws.isOwner, isFalse);
      expect(ws.isAdmin, isTrue);
      expect(ws.canWrite, isTrue);
      expect(ws.isReadOnly, isFalse);
    });

    test('Writer/Member has write access but cannot manage members', () {
      final wsWriter = WorkspaceEntity(
        id: 'ws-3',
        name: 'Sharma Family',
        type: 'family',
        ownerId: 'usr-1',
        userRole: 'writer',
        createdAt: DateTime.now(),
      );

      expect(wsWriter.isOwner, isFalse);
      expect(wsWriter.isAdmin, isFalse);
      expect(wsWriter.canWrite, isTrue);
      expect(wsWriter.isReadOnly, isFalse);

      final wsMember = wsWriter.copyWith(userRole: 'member');
      expect(wsMember.canWrite, isTrue);
      expect(wsMember.isAdmin, isFalse);
    });

    test('Viewer/Read_only is strictly restricted to read-only', () {
      final wsViewer = WorkspaceEntity(
        id: 'ws-4',
        name: 'Sharma Family',
        type: 'family',
        ownerId: 'usr-1',
        userRole: 'viewer',
        createdAt: DateTime.now(),
      );

      expect(wsViewer.isOwner, isFalse);
      expect(wsViewer.isAdmin, isFalse);
      expect(wsViewer.canWrite, isFalse);
      expect(wsViewer.isReadOnly, isTrue);

      final wsReadOnly = wsViewer.copyWith(userRole: 'read_only');
      expect(wsReadOnly.canWrite, isFalse);
      expect(wsReadOnly.isReadOnly, isTrue);
    });
  });

  group('WorkspaceMemberEntity initials and roles', () {
    test('Calculates initials correctly from full name or email', () {
      final member1 = WorkspaceMemberEntity(
        memberId: 'mem-1',
        userId: 'usr-1',
        email: 'shubham.sharma@gmail.com',
        fullName: 'Shubham Sharma',
        role: 'owner',
        joinedAt: DateTime.now(),
        isOwner: true,
      );
      expect(member1.initials, 'SS');
      expect(member1.displayName, 'Shubham Sharma');
      expect(member1.isAdmin, isTrue);
      expect(member1.canWrite, isTrue);

      final member2 = WorkspaceMemberEntity(
        memberId: 'mem-2',
        userId: 'usr-2',
        email: 'viewer@apna.family',
        fullName: '',
        role: 'read_only',
        joinedAt: DateTime.now(),
        isOwner: false,
      );
      expect(member2.initials, 'V');
      expect(member2.displayName, 'viewer');
      expect(member2.isAdmin, isFalse);
      expect(member2.canWrite, isFalse);
      expect(member2.isReadOnly, isTrue);
    });
  });
}
