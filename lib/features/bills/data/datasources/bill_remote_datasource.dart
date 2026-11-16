import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/configuration/supabase_config.dart';
import '../models/bill_model.dart';

abstract interface class BillRemoteDataSource {
  Future<List<BillModel>> getBills(String workspaceId);
  Future<BillModel> addBill(BillModel bill);
  Future<BillModel> markBillAsPaid(String billId, {String? reference});
  Future<void> deleteBill(String billId);
}

class BillRemoteDataSourceImpl implements BillRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<BillModel>> getBills(String workspaceId) async {
    if (!SupabaseConfig.isConfigured) return [];

    final response = await _client
        .from('bills')
        .select()
        .eq('workspace_id', workspaceId)
        .isFilter('deleted_at', null)
        .order('due_date', ascending: true);

    return (response as List)
        .map((row) => BillModel.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  @override
  Future<BillModel> addBill(BillModel bill) async {
    if (!SupabaseConfig.isConfigured) return bill;

    final payload = bill.toMap();
    await _client.from('bills').insert(payload);
    return bill;
  }

  @override
  Future<BillModel> markBillAsPaid(String billId, {String? reference}) async {
    if (!SupabaseConfig.isConfigured) throw Exception('Supabase not configured');

    final response = await _client
        .from('bills')
        .update({
          'payment_status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
          'payment_reference': reference ?? 'UPI-DIRECT-TXN',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', billId)
        .select()
        .single();

    return BillModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> deleteBill(String billId) async {
    if (!SupabaseConfig.isConfigured) return;

    await _client
        .from('bills')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', billId);
  }
}
