import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:apna/app/theme/app_colors.dart';
import 'package:apna/app/theme/app_typography.dart';
import 'package:apna/features/authentication/presentation/providers/auth_providers.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../domain/entities/health_record_entity.dart';
import '../providers/health_providers.dart';

class HealthPage extends ConsumerStatefulWidget {
  const HealthPage({super.key});

  @override
  ConsumerState<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends ConsumerState<HealthPage> {
  String _selectedType = 'ALL';
  static const _uuid = Uuid();

  void _showAddRecordDialog(BuildContext context) {
    final titleController = TextEditingController();
    final memberController = TextEditingController(text: 'Self');
    final doctorController = TextEditingController();
    final hospitalController = TextEditingController();
    final detailsController = TextEditingController();
    String recordType = 'prescription';
    DateTime recordDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Health & Medical Record', style: ApnaTypography.headingSmall),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title / Treatment *',
                      hintText: 'e.g. Pediatric Vaccination or Blood Test',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: memberController,
                          decoration: InputDecoration(
                            labelText: 'Family Member *',
                            hintText: 'e.g. Self, Spouse, Child',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: recordType,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                            DropdownMenuItem(value: 'lab_report', child: Text('Lab Report')),
                            DropdownMenuItem(value: 'doctor_visit', child: Text('Doctor Visit')),
                            DropdownMenuItem(value: 'vaccine', child: Text('Vaccine')),
                            DropdownMenuItem(value: 'allergy', child: Text('Allergy Note')),
                          ],
                          onChanged: (val) => setDialogState(() => recordType = val ?? 'prescription'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: doctorController,
                          decoration: InputDecoration(
                            labelText: 'Doctor Name',
                            hintText: 'e.g. Dr. R. Sharma',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: hospitalController,
                          decoration: InputDecoration(
                            labelText: 'Hospital / Clinic',
                            hintText: 'e.g. Apollo Hospital',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Dosage / Diagnosis / Details',
                      hintText: 'e.g. Amoxicillin 500mg twice daily for 5 days',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Date: ${DateFormat('dd MMM yyyy').format(recordDate)}'),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: recordDate,
                        firstDate: DateTime(1980),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() => recordDate = picked);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: ApnaColors.border),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: ApnaColors.primary),
              onPressed: () async {
                final title = titleController.text.trim();
                final member = memberController.text.trim();
                if (title.isEmpty || member.isEmpty) return;

                final user = ref.read(authControllerProvider).valueOrNull;
                final ws = ref.read(activeWorkspaceProvider);
                if (user == null || ws == null) return;

                final record = HealthRecordEntity(
                  id: _uuid.v4(),
                  workspaceId: ws.id,
                  ownerId: user.id,
                  memberName: member,
                  recordType: recordType,
                  title: title,
                  doctorName: doctorController.text.trim(),
                  clinicHospital: hospitalController.text.trim(),
                  details: detailsController.text.trim(),
                  recordDate: recordDate,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await ref.read(healthRepositoryProvider).addRecord(record);
                ref.invalidate(workspaceHealthRecordsProvider);
                if (context.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'prescription':
        return ApnaColors.blue;
      case 'lab_report':
        return Colors.teal;
      case 'doctor_visit':
        return Colors.indigo;
      case 'vaccine':
        return ApnaColors.success;
      case 'allergy':
        return ApnaColors.error;
      default:
        return ApnaColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(workspaceHealthRecordsProvider);

    return Scaffold(
      backgroundColor: ApnaColors.background,
      appBar: AppBar(
        title: const Text('Health & Medical Vault', style: ApnaTypography.headingSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(workspaceHealthRecordsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecordDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Record'),
        backgroundColor: ApnaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (records) {
          final filtered = records.where((r) {
            if (_selectedType == 'ALL') return true;
            return r.recordType.toLowerCase() == _selectedType.toLowerCase();
          }).toList();

          return Column(
            children: [
              // Emergency Info Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade50, Colors.red.shade100.withValues(alpha: 0.4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 20,
                      child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family Health & Emergency Vault',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'All records encrypted with DPDP Act compliance. Instantly accessible in emergencies.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    'ALL',
                    'prescription',
                    'lab_report',
                    'doctor_visit',
                    'vaccine',
                    'allergy',
                  ].map((t) {
                    final isSel = _selectedType == t;
                    final label = t == 'ALL'
                        ? 'All Records'
                        : t.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSel,
                        label: Text(label),
                        onSelected: (_) => setState(() => _selectedType = t),
                        selectedColor: ApnaColors.primary.withOpacity(0.15),
                        checkmarkColor: ApnaColors.primary,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Records List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_border_rounded, size: 64, color: ApnaColors.border),
                            const SizedBox(height: 16),
                            const Text('No health records found', style: ApnaTypography.headingSmall),
                            const SizedBox(height: 8),
                            const Text('Keep prescriptions, blood test results, and vaccine cards safe.', style: ApnaTypography.bodyMedium),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _showAddRecordDialog(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Health Record'),
                              style: FilledButton.styleFrom(backgroundColor: ApnaColors.primary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final rec = filtered[idx];
                          final color = _getTypeColor(rec.recordType);

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: ApnaColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          rec.recordType.replaceAll('_', ' ').toUpperCase(),
                                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ApnaColors.background,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: ApnaColors.border),
                                        ),
                                        child: Text(
                                          rec.memberName,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(rec.recordDate),
                                        style: const TextStyle(fontSize: 12, color: ApnaColors.textSecondary),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                                        onPressed: () async {
                                          await ref.read(healthRepositoryProvider).deleteRecord(rec.id);
                                          ref.invalidate(workspaceHealthRecordsProvider);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    rec.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (rec.doctorName != null && rec.doctorName!.isNotEmpty ||
                                      rec.clinicHospital != null && rec.clinicHospital!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_pin_circle_outlined, size: 14, color: ApnaColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          [rec.doctorName, rec.clinicHospital].where((e) => e != null && e.isNotEmpty).join(' • '),
                                          style: const TextStyle(fontSize: 13, color: ApnaColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (rec.details.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      rec.details,
                                      style: const TextStyle(fontSize: 13, color: ApnaColors.textPrimary, height: 1.4),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
