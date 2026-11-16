import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabase {
  static Database? _database;

  static Future<Database?> get instance async {
    if (kIsWeb) return null; // Web platforms rely on direct Supabase & browser secure storage
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database;
  }

  static Future<Database?> _initDatabase() async {
    if (kIsWeb) return null;

    try {
      if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final directory = await getApplicationDocumentsDirectory();
      final dbPath = p.join(directory.path, 'apna_local_vault.db');

      return await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          // Legal Consents Ledger
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_legal_consents (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL,
              terms_version TEXT NOT NULL,
              privacy_version TEXT NOT NULL,
              consent_purposes TEXT NOT NULL,
              device_id TEXT,
              consented_at TEXT NOT NULL,
              revoked_at TEXT
            );
          ''');

          // Documents
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_documents (
              id TEXT PRIMARY KEY,
              workspace_id TEXT NOT NULL,
              owner_id TEXT NOT NULL,
              title TEXT NOT NULL,
              category TEXT NOT NULL,
              tags TEXT,
              document_number TEXT,
              file_name TEXT,
              file_size_bytes INTEGER,
              mime_type TEXT,
              local_file_path TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            );
          ''');

          // Sync Outbox
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_sync_outbox (
              id TEXT PRIMARY KEY,
              entity_type TEXT NOT NULL,
              entity_id TEXT NOT NULL,
              operation TEXT NOT NULL,
              payload TEXT NOT NULL,
              idempotency_key TEXT NOT NULL UNIQUE,
              attempts INTEGER DEFAULT 0,
              status TEXT DEFAULT 'PENDING',
              last_error TEXT,
              created_at TEXT NOT NULL
            );
          ''');
        },
      );
    } catch (_) {
      return null;
    }
  }
}
