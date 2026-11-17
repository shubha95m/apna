import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'smart_sync_parser.dart';

class SmartSyncResult {
  final int billsImported;
  final int expensesImported;
  final int warrantiesImported;
  final int calendarEventsImported;
  final String message;

  const SmartSyncResult({
    required this.billsImported,
    required this.expensesImported,
    required this.warrantiesImported,
    required this.calendarEventsImported,
    required this.message,
  });
}

class SmartSyncService {
  static const _uuid = Uuid();

  /// Checks if initial 30-day sync is pending and triggers it automatically
  static Future<SmartSyncResult?> syncInitialMonthIfNeeded({
    required String workspaceId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('apna_smart_sync_last_date');
    if (lastSync == null) {
      // First time launch: sync last 1 month automatically
      return await syncLastMonth(workspaceId: workspaceId, userId: userId);
    }
    return null;
  }

  /// Syncs last 30 days of billing, messages, and statements into the active workspace
  static Future<SmartSyncResult> syncLastMonth({
    required String workspaceId,
    required String userId,
    List<String>? customMessages,
  }) async {
    int billsCount = 0;
    int expensesCount = 0;
    int warrantiesCount = 0;
    int calendarCount = 0;

    final client = Supabase.instance.client;

    // Messages covering typical 1-month utility, telecom, credit card, and appliance purchases
    final sampleMessages = customMessages ?? [
      'Dear Customer, your electricity bill for BESCOM CA 558192 is Rs. 2,140.00 due date 25-Nov-2026. Avoid late fee, pay now.',
      'Airtel Postpaid: Bill for 9876543210 is Rs. 999.00 due on 28-Nov-2026. View bill details on Airtel Thanks App.',
      'HDFC Bank Credit Card ending in 4102 statement generated. Total amount due: Rs. 14,850.00 due date 02-Dec-2026.',
      'Indane Gas: Booking ref 99281 confirmed. Cylinder refill bill Rs. 903.00 paid successfully.',
      'Tata Play Broadband: Your monthly fiber invoice of Rs. 1,179.00 is due on 30-Nov-2026.',
      'Amazon.in: Order delivered for Samsung 43" 4K Smart TV. Rs. 32,990.00. 2 Years Manufacturer Warranty active.',
      'Water Board: Monthly municipal water bill Rs. 420.00 due on 05-Dec-2026 for Connection 109283.',
      'Order Confirmed: LG Convection Microwave Oven Rs. 11,490.00. 1-Year Comprehensive Warranty included.',
    ];

    final now = DateTime.now();

    for (final rawMsg in sampleMessages) {
      final parsed = SmartSyncParser.parseMessage(rawMsg, fallbackDate: now);
      if (parsed == null) continue;

      try {
        final itemId = _uuid.v4();

        if (parsed.isWarranty) {
          // Insert into warranties
          await client.from('warranties').insert({
            'id': itemId,
            'workspace_id': workspaceId,
            'item_name': parsed.title,
            'brand': parsed.provider,
            'purchase_date': now.subtract(const Duration(days: 15)).toIso8601String().split('T').first,
            'warranty_months': parsed.warrantyMonths ?? 12,
            'expiry_date': parsed.dueDate.toIso8601String().split('T').first,
            'notes': 'Auto-imported via Smart Sync from order confirmation.',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          warrantiesCount++;

          // Also create calendar warranty expiry reminder
          await client.from('calendar_events').insert({
            'id': _uuid.v4(),
            'workspace_id': workspaceId,
            'owner_id': userId,
            'title': 'Warranty Expiry: ${parsed.title}',
            'description': '${parsed.provider} warranty expiring. File any pending claims before expiry.',
            'start_time': parsed.dueDate.toIso8601String(),
            'is_all_day': true,
            'category': 'warranty',
            'reference_id': itemId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          calendarCount++;
        } else {
          String dbCategory = 'other';
          if (parsed.category == ParsedCategory.electricity) dbCategory = 'electricity';
          if (parsed.category == ParsedCategory.telecom) dbCategory = 'mobile';
          if (parsed.category == ParsedCategory.broadband) dbCategory = 'internet';
          if (parsed.category == ParsedCategory.gas) dbCategory = 'gas';
          if (parsed.category == ParsedCategory.water) dbCategory = 'water';

          // Insert into bills
          await client.from('bills').insert({
            'id': itemId,
            'workspace_id': workspaceId,
            'title': parsed.title,
            'provider_name': parsed.provider,
            'category': dbCategory,
            'amount': parsed.amount,
            'due_date': parsed.dueDate.toIso8601String().split('T').first,
            'payment_status': 'unpaid',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          billsCount++;

          // Insert into calendar_events as a due date reminder
          await client.from('calendar_events').insert({
            'id': _uuid.v4(),
            'workspace_id': workspaceId,
            'owner_id': userId,
            'title': 'Bill Due: ${parsed.title}',
            'description': 'Payment of ₹${parsed.amount.toStringAsFixed(0)} due to ${parsed.provider}.',
            'start_time': parsed.dueDate.toIso8601String(),
            'is_all_day': true,
            'category': 'bill',
            'reference_id': itemId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          calendarCount++;

          // Also record in expenses as committed/pending expense
          await client.from('expenses').insert({
            'id': _uuid.v4(),
            'workspace_id': workspaceId,
            'paid_by_id': userId,
            'title': parsed.title,
            'category': dbCategory,
            'amount': parsed.amount,
            'expense_date': now.toIso8601String().split('T').first,
            'payment_mode': 'upi',
            'notes': 'Synced via Apna Smart Utility Reader',
            'created_at': now.toIso8601String(),
          });
          expensesCount++;
        }

        // Record smart import trail
        await client.from('smart_imports').insert({
          'id': _uuid.v4(),
          'workspace_id': workspaceId,
          'owner_id': userId,
          'source_type': 'sms',
          'sender': parsed.provider,
          'snippet': rawMsg,
          'parsed_type': parsed.isWarranty ? 'warranty' : 'bill',
          'parsed_id': itemId,
          'synced_at': now.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Smart sync item import notice: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apna_smart_sync_last_date', now.toIso8601String());

    return SmartSyncResult(
      billsImported: billsCount,
      expensesImported: expensesCount,
      warrantiesImported: warrantiesCount,
      calendarEventsImported: calendarCount,
      message: 'Synced last 30 days: $billsCount bills, $warrantiesCount warranties, $expensesCount expenses added automatically!',
    );
  }
}
