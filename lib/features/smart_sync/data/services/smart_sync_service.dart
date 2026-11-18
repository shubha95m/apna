import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'email_sync_service.dart';
import 'smart_sync_parser.dart';
import 'sms_native_service.dart';

class SmartSyncResult {
  final int billsImported;
  final int expensesImported;
  final int warrantiesImported;
  final int calendarEventsImported;
  final int duplicatesSkipped;
  final String message;

  const SmartSyncResult({
    required this.billsImported,
    required this.expensesImported,
    required this.warrantiesImported,
    required this.calendarEventsImported,
    required this.duplicatesSkipped,
    required this.message,
  });
}

class SmartSyncService {
  static const _uuid = Uuid();

  /// Checks if initial 30-day sync is pending and triggers it automatically without interrupting cold start
  static Future<SmartSyncResult?> syncInitialMonthIfNeeded({
    required String workspaceId,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('apna_smart_sync_last_date');
    if (lastSync == null) {
      // First time launch: sync last 1 month automatically
      return await syncLastMonth(
        workspaceId: workspaceId,
        userId: userId,
        fetchFromDeviceSms: true,
      );
    }
    return null;
  }

  /// Syncs real billing, messages, and statements into the active workspace.
  /// Strictly prevents duplicate entries across repeated syncs.
  static Future<SmartSyncResult> syncLastMonth({
    required String workspaceId,
    required String userId,
    List<String>? customMessages,
    bool fetchFromDeviceSms = true,
    bool fetchFromGmail = false,
  }) async {
    int billsCount = 0;
    int expensesCount = 0;
    int warrantiesCount = 0;
    int calendarCount = 0;
    int duplicatesSkipped = 0;

    final client = Supabase.instance.client;
    final now = DateTime.now();

    // 1. GATHER REAL MESSAGES FROM DEVICE AND INTEGRATIONS
    final messagesToParse = <({String text, String sender, DateTime date})>[];

    if (customMessages != null && customMessages.isNotEmpty) {
      for (final msg in customMessages) {
        messagesToParse.add((text: msg, sender: 'User Import', date: now));
      }
    } else {
      // 1A. Fetch from native Android device SMS inbox if permitted
      if (fetchFromDeviceSms && SmsNativeService.isSupportedPlatform) {
        try {
          final hasPerm = await SmsNativeService.hasPermission();
          if (hasPerm) {
            final realSms = await SmsNativeService.getRecentSms(days: 30);
            for (final s in realSms) {
              messagesToParse.add((text: s.body, sender: s.address, date: s.date));
            }
          }
        } catch (e) {
          debugPrint('Device SMS read error: $e');
        }
      }

      // 1B. Fetch from Gmail API if requested
      if (fetchFromGmail) {
        try {
          final emails = await EmailSyncService.fetchRecentBillEmails();
          for (final em in emails) {
            messagesToParse.add((text: em.snippet, sender: em.from, date: em.date));
          }
        } catch (e) {
          debugPrint('Gmail sync notice: $e');
        }
      }
    }

    // If no real messages exist (e.g. simulator or web without imported text), exit cleanly without mock data
    if (messagesToParse.isEmpty) {
      return const SmartSyncResult(
        billsImported: 0,
        expensesImported: 0,
        warrantiesImported: 0,
        calendarEventsImported: 0,
        duplicatesSkipped: 0,
        message: 'No new SMS statements found. Grant SMS permission or paste an email/statement.',
      );
    }

    // 2. LOAD EXISTING RECORDS FOR DEDUPLICATION / IDEMPOTENCY
    final existingBillKeys = <String>{};
    final existingExpenseKeys = <String>{};
    final existingWarrantyKeys = <String>{};
    final existingSnippetHashes = <String>{};

    try {
      final billsRes = await client
          .from('bills')
          .select('provider_name, amount, due_date, consumer_number')
          .eq('workspace_id', workspaceId);
      for (final r in billsRes) {
        final key = '${r['provider_name']}_${r['amount']}_${r['due_date']}_${r['consumer_number'] ?? ''}'.toLowerCase();
        existingBillKeys.add(key);
      }

      final expensesRes = await client
          .from('expenses')
          .select('title, amount, expense_date')
          .eq('workspace_id', workspaceId);
      for (final r in expensesRes) {
        final key = '${r['title']}_${r['amount']}_${r['expense_date']}'.toLowerCase();
        existingExpenseKeys.add(key);
      }

      final warrantiesRes = await client
          .from('warranties')
          .select('brand, item_name, expiry_date')
          .eq('workspace_id', workspaceId);
      for (final r in warrantiesRes) {
        final key = '${r['brand']}_${r['item_name']}_${r['expiry_date']}'.toLowerCase();
        existingWarrantyKeys.add(key);
      }

      final importsRes = await client
          .from('smart_imports')
          .select('snippet')
          .eq('workspace_id', workspaceId);
      for (final r in importsRes) {
        final snip = r['snippet']?.toString().trim() ?? '';
        if (snip.isNotEmpty) {
          existingSnippetHashes.add(snip);
        }
      }
    } catch (e) {
      debugPrint('Warning pre-fetching deduplication keys: $e');
    }

    // 3. PARSE AND PROCESS MESSAGES
    for (final item in messagesToParse) {
      final parsed = SmartSyncParser.parseMessage(
        item.text,
        sender: item.sender,
        fallbackDate: item.date,
      );

      if (parsed == null) continue;

      // Check intra-batch and persistent snippet deduplication
      if (existingSnippetHashes.contains(parsed.deduplicationHash) ||
          existingSnippetHashes.contains(item.text.trim())) {
        duplicatesSkipped++;
        continue;
      }

      try {
        final itemId = _uuid.v4();

        // 3A. Handle Warranties
        if (parsed.type == SmartTransactionType.warrantyPurchase) {
          final warrantyKey = '${parsed.providerOrMerchant}_${parsed.title}_${parsed.date.toIso8601String().split('T').first}'.toLowerCase();
          if (existingWarrantyKeys.contains(warrantyKey)) {
            duplicatesSkipped++;
            continue;
          }

          await client.from('warranties').insert({
            'id': itemId,
            'workspace_id': workspaceId,
            'item_name': parsed.title,
            'brand': parsed.providerOrMerchant,
            'purchase_date': item.date.toIso8601String().split('T').first,
            'warranty_months': parsed.warrantyMonths ?? 12,
            'expiry_date': parsed.date.toIso8601String().split('T').first,
            'notes': parsed.accountOrCard != null
                ? 'Paid via ${parsed.accountOrCard}. Auto-imported via Apna Smart Sync.'
                : 'Auto-imported via Apna Smart Sync.',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          warrantiesCount++;
          existingWarrantyKeys.add(warrantyKey);

          // Add to calendar
          await client.from('calendar_events').insert({
            'id': _uuid.v4(),
            'workspace_id': workspaceId,
            'owner_id': userId,
            'title': 'Warranty Expiry: ${parsed.title}',
            'description': '${parsed.providerOrMerchant} warranty expiring. Check product health & claims.',
            'start_time': parsed.date.toIso8601String(),
            'is_all_day': true,
            'category': 'warranty',
            'reference_id': itemId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          calendarCount++;
        }
        // 3B. Handle Upcoming Bills
        else if (parsed.type == SmartTransactionType.upcomingBill) {
          final billKey = '${parsed.providerOrMerchant}_${parsed.amount}_${parsed.date.toIso8601String().split('T').first}_${parsed.referenceNumber ?? ''}'.toLowerCase();
          if (existingBillKeys.contains(billKey)) {
            duplicatesSkipped++;
            continue;
          }

          await client.from('bills').insert({
            'id': itemId,
            'workspace_id': workspaceId,
            'title': parsed.title,
            'provider_name': parsed.providerOrMerchant,
            'category': parsed.billCategory.name,
            'amount': parsed.amount,
            'due_date': parsed.date.toIso8601String().split('T').first,
            'consumer_number': parsed.referenceNumber,
            'payment_status': 'unpaid',
            'upi_vpa': parsed.upiVpa, // Real extracted or official BBPS VPA
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          billsCount++;
          existingBillKeys.add(billKey);

          // Add to calendar
          await client.from('calendar_events').insert({
            'id': _uuid.v4(),
            'workspace_id': workspaceId,
            'owner_id': userId,
            'title': 'Bill Due: ${parsed.title}',
            'description': 'Payment of ₹${parsed.amount.toStringAsFixed(0)} due to ${parsed.providerOrMerchant}.',
            'start_time': parsed.date.toIso8601String(),
            'is_all_day': true,
            'category': 'bill',
            'reference_id': itemId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          calendarCount++;
        }
        // 3C. Handle Debits & Expenses (and Credits/Income)
        else {
          final expenseKey = '${parsed.title}_${parsed.amount}_${parsed.date.toIso8601String().split('T').first}'.toLowerCase();
          if (existingExpenseKeys.contains(expenseKey)) {
            duplicatesSkipped++;
            continue;
          }

          final paymentMode = parsed.accountOrCard != null && parsed.accountOrCard!.contains('Card')
              ? 'card'
              : 'upi';

          String notes = '';
          if (parsed.accountOrCard != null) {
            notes += '[${parsed.accountOrCard}] ';
          }
          if (parsed.referenceNumber != null && parsed.referenceNumber!.isNotEmpty) {
            notes += 'Ref: ${parsed.referenceNumber} ';
          }
          if (parsed.type == SmartTransactionType.creditIncome) {
            notes += '(Credit / Income)';
          } else {
            notes += 'Auto-detected transaction';
          }

          await client.from('expenses').insert({
            'id': itemId,
            'workspace_id': workspaceId,
            'paid_by_id': userId,
            'title': parsed.title,
            'category': parsed.category,
            'amount': parsed.amount,
            'expense_date': parsed.date.toIso8601String().split('T').first,
            'payment_mode': paymentMode,
            'notes': notes.trim(),
            'created_at': now.toIso8601String(),
          });
          expensesCount++;
          existingExpenseKeys.add(expenseKey);
        }

        // Record import fingerprint in smart_imports table
        await client.from('smart_imports').insert({
          'id': _uuid.v4(),
          'workspace_id': workspaceId,
          'owner_id': userId,
          'source_type': item.sender.contains('@') ? 'email' : 'sms',
          'sender': item.sender,
          'snippet': parsed.deduplicationHash,
          'parsed_type': parsed.type.name,
          'parsed_id': itemId,
          'synced_at': now.toIso8601String(),
        });
        existingSnippetHashes.add(parsed.deduplicationHash);
      } catch (e) {
        debugPrint('Smart sync item import notice: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apna_smart_sync_last_date', now.toIso8601String());

    final summaryParts = <String>[];
    if (billsCount > 0) summaryParts.add('$billsCount bills');
    if (expensesCount > 0) summaryParts.add('$expensesCount expenses');
    if (warrantiesCount > 0) summaryParts.add('$warrantiesCount warranties');

    final summaryText = summaryParts.isEmpty
        ? 'Everything is up to date!'
        : 'Imported: ${summaryParts.join(", ")}';

    final duplicateNotice = duplicatesSkipped > 0
        ? ' ($duplicatesSkipped duplicate records skipped)'
        : '';

    return SmartSyncResult(
      billsImported: billsCount,
      expensesImported: expensesCount,
      warrantiesImported: warrantiesCount,
      calendarEventsImported: calendarCount,
      duplicatesSkipped: duplicatesSkipped,
      message: '$summaryText$duplicateNotice',
    );
  }
}
