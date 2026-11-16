import 'package:flutter_test/flutter_test.dart';
import 'package:apna/features/tasks/domain/entities/task_entity.dart';
import 'package:apna/features/tasks/data/models/task_model.dart';

void main() {
  group('TaskEntity & TaskModel', () {
    test('TaskModel correctly maps to/from Supabase payload', () {
      final now = DateTime.now();
      final model = TaskModel(
        id: 't-123',
        workspaceId: 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a02',
        creatorId: 'u-1',
        title: 'Submit Society Maintenance',
        description: 'Via UPI or cheque',
        priority: 'high',
        status: 'pending',
        dueDate: now.add(const Duration(days: 2)),
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toMap();
      expect(map['title'], 'Submit Society Maintenance');
      expect(map['priority'], 'high');
      expect(map['status'], 'pending');

      final deserialized = TaskModel.fromMap({
        'id': 't-123',
        'workspace_id': 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380a02',
        'creator_id': 'u-1',
        'title': 'Submit Society Maintenance',
        'description': 'Via UPI or cheque',
        'priority': 'high',
        'status': 'pending',
        'due_date': now.add(const Duration(days: 2)).toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      expect(deserialized.id, 't-123');
      expect(deserialized.isCompleted, isFalse);

      final completed = deserialized.copyWith(status: 'completed');
      expect(completed.isCompleted, isTrue);
    });
  });
}
