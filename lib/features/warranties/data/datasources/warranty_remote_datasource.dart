import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/configuration/supabase_config.dart';
import '../models/warranty_model.dart';

abstract interface class WarrantyRemoteDataSource {
  Future<List<WarrantyModel>> getWarranties(String workspaceId);
  Future<WarrantyModel> addWarranty(WarrantyModel warranty);
  Future<void> deleteWarranty(String warrantyId);
}

class WarrantyRemoteDataSourceImpl implements WarrantyRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<WarrantyModel>> getWarranties(String workspaceId) async {
    if (!SupabaseConfig.isConfigured) return [];

    final response = await _client
        .from('warranties')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('expiry_date', ascending: true);

    return (response as List)
        .map((row) => WarrantyModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<WarrantyModel> addWarranty(WarrantyModel warranty) async {
    if (!SupabaseConfig.isConfigured) return warranty;

    final payload = warranty.toMap();
    await _client.from('warranties').insert(payload);
    return warranty;
  }

  @override
  Future<void> deleteWarranty(String warrantyId) async {
    if (!SupabaseConfig.isConfigured) return;

    await _client
        .from('warranties')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', warrantyId);
  }
}
