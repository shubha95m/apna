import 'package:flutter_test/flutter_test.dart';
import 'package:apna/features/notes/data/models/note_model.dart';
import 'package:apna/features/grocery/data/models/grocery_item_model.dart';
import 'package:apna/features/health/data/models/health_record_model.dart';
import 'package:apna/features/calendar/data/models/calendar_event_model.dart';

void main() {
  group('Pillar Models Serialisation & Mapping Tests', () {
    test('NoteModel maps to/from Supabase payload correctly', () {
      final json = {
        'id': 'note-1',
        'workspace_id': 'ws-1',
        'owner_id': 'user-1',
        'title': 'Emergency Lockbox Code',
        'content': 'Key in master bedroom second drawer.',
        'tags': ['security', 'home'],
        'is_pinned': true,
        'created_at': '2026-11-17T12:00:00Z',
        'updated_at': '2026-11-17T12:00:00Z',
      };

      final model = NoteModel.fromJson(json);
      expect(model.id, equals('note-1'));
      expect(model.title, equals('Emergency Lockbox Code'));
      expect(model.isPinned, isTrue);
      expect(model.tags, contains('security'));

      final outJson = model.toJson();
      expect(outJson['title'], equals('Emergency Lockbox Code'));
      expect(outJson['is_pinned'], isTrue);
    });

    test('GroceryItemModel maps to/from Supabase payload correctly', () {
      final json = {
        'id': 'groc-1',
        'workspace_id': 'ws-1',
        'owner_id': 'user-1',
        'name': 'Aashirvaad Atta',
        'quantity': 5.0,
        'unit': 'kg',
        'category': 'pantry',
        'is_purchased': false,
        'created_at': '2026-11-17T12:00:00Z',
        'updated_at': '2026-11-17T12:00:00Z',
      };

      final model = GroceryItemModel.fromJson(json);
      expect(model.name, equals('Aashirvaad Atta'));
      expect(model.quantity, equals(5.0));
      expect(model.unit, equals('kg'));
      expect(model.isPurchased, isFalse);

      final outJson = model.toJson();
      expect(outJson['name'], equals('Aashirvaad Atta'));
      expect(outJson['quantity'], equals(5.0));
    });

    test('HealthRecordModel maps to/from Supabase payload correctly', () {
      final json = {
        'id': 'health-1',
        'workspace_id': 'ws-1',
        'owner_id': 'user-1',
        'member_name': 'Papa',
        'record_type': 'prescription',
        'title': 'Blood Pressure Prescription',
        'details': 'Take blood pressure medication daily after breakfast',
        'doctor_name': 'Dr. Sharma',
        'clinic_hospital': 'Apollo Clinic',
        'record_date': '2026-11-10T00:00:00Z',
        'created_at': '2026-11-17T12:00:00Z',
        'updated_at': '2026-11-17T12:00:00Z',
      };

      final model = HealthRecordModel.fromJson(json);
      expect(model.memberName, equals('Papa'));
      expect(model.recordType, equals('prescription'));
      expect(model.doctorName, equals('Dr. Sharma'));

      final outJson = model.toJson();
      expect(outJson['member_name'], equals('Papa'));
    });

    test('CalendarEventModel maps to/from Supabase payload correctly', () {
      final json = {
        'id': 'cal-1',
        'workspace_id': 'ws-1',
        'owner_id': 'user-1',
        'title': 'Electricity Bill Due',
        'description': 'Pay BESCOM ₹2,140 before late fee',
        'start_time': '2026-11-25T00:00:00Z',
        'is_all_day': true,
        'category': 'bill',
        'created_at': '2026-11-17T12:00:00Z',
        'updated_at': '2026-11-17T12:00:00Z',
      };

      final model = CalendarEventModel.fromJson(json);
      expect(model.title, equals('Electricity Bill Due'));
      expect(model.category, equals('bill'));
      expect(model.isAllDay, isTrue);

      final outJson = model.toJson();
      expect(outJson['title'], equals('Electricity Bill Due'));
    });
  });
}
