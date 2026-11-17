import '../entities/health_record_entity.dart';

abstract class HealthRepository {
  Future<List<HealthRecordEntity>> getRecords(String workspaceId);
  Future<HealthRecordEntity> addRecord(HealthRecordEntity record);
  Future<void> deleteRecord(String id);
}
