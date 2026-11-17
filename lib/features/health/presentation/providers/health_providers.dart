import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:apna/features/documents/presentation/providers/document_providers.dart';
import '../../data/repositories/health_repository_impl.dart';
import '../../domain/entities/health_record_entity.dart';
import '../../domain/repositories/health_repository.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepositoryImpl(Supabase.instance.client);
});

final workspaceHealthRecordsProvider = FutureProvider<List<HealthRecordEntity>>((ref) async {
  final activeWorkspace = ref.watch(activeWorkspaceProvider);
  if (activeWorkspace == null) return [];
  final repo = ref.watch(healthRepositoryProvider);
  return repo.getRecords(activeWorkspace.id);
});
