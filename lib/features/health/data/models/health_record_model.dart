import '../../domain/entities/health_record_entity.dart';

class HealthRecordModel extends HealthRecordEntity {
  const HealthRecordModel({
    required super.id,
    required super.workspaceId,
    required super.ownerId,
    required super.memberName,
    required super.recordType,
    required super.title,
    super.details,
    super.doctorName,
    super.clinicHospital,
    required super.recordDate,
    super.documentId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json) {
    return HealthRecordModel(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      ownerId: json['owner_id'] as String,
      memberName: json['member_name'] as String,
      recordType: json['record_type'] as String,
      title: json['title'] as String,
      details: json['details'] as String? ?? '',
      doctorName: json['doctor_name'] as String?,
      clinicHospital: json['clinic_hospital'] as String?,
      recordDate: DateTime.parse(json['record_date'] as String),
      documentId: json['document_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'owner_id': ownerId,
      'member_name': memberName,
      'record_type': recordType,
      'title': title,
      'details': details,
      'doctor_name': doctorName,
      'clinic_hospital': clinicHospital,
      'record_date': recordDate.toIso8601String().split('T').first,
      'document_id': documentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
