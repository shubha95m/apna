class HealthRecordEntity {
  final String id;
  final String workspaceId;
  final String ownerId;
  final String memberName;
  final String recordType; // prescription, lab_report, doctor_visit, vaccine, allergy
  final String title;
  final String details;
  final String? doctorName;
  final String? clinicHospital;
  final DateTime recordDate;
  final String? documentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HealthRecordEntity({
    required this.id,
    required this.workspaceId,
    required this.ownerId,
    required this.memberName,
    required this.recordType,
    required this.title,
    this.details = '',
    this.doctorName,
    this.clinicHospital,
    required this.recordDate,
    this.documentId,
    required this.createdAt,
    required this.updatedAt,
  });
}
