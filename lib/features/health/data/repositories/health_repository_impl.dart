import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/health_record_entity.dart';
import '../../domain/repositories/health_repository.dart';
import '../models/health_record_model.dart';

class HealthRepositoryImpl implements HealthRepository {
  final SupabaseClient _client;

  HealthRepositoryImpl(this._client);

  @override
  Future<List<HealthRecordEntity>> getRecords(String workspaceId) async {
    final response = await _client
        .from('health_records')
        .select()
        .eq('workspace_id', workspaceId)
        .order('record_date', ascending: false);

    return (response as List).map((json) => HealthRecordModel.fromJson(json)).toList();
  }

  @override
  Future<HealthRecordEntity> addRecord(HealthRecordEntity record) async {
    final model = HealthRecordModel(
      id: record.id,
      workspaceId: record.workspaceId,
      ownerId: record.ownerId,
      memberName: record.memberName,
      recordType: record.recordType,
      title: record.title,
      details: record.details,
      doctorName: record.doctorName,
      clinicHospital: record.clinicHospital,
      recordDate: record.recordDate,
      documentId: record.documentId,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );

    final res = await _client.from('health_records').insert(model.toJson()).select().single();
    return HealthRecordModel.fromJson(res);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _client.from('health_records').delete().eq('id', id);
  }
}
