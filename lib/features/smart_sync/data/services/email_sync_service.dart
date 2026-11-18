import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class EmailStatementMessage {
  final String id;
  final String from;
  final String subject;
  final String snippet;
  final DateTime date;

  const EmailStatementMessage({
    required this.id,
    required this.from,
    required this.subject,
    required this.snippet,
    required this.date,
  });
}

class EmailSyncService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
    ],
  );

  /// Returns current signed in Google account if any
  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Connects with Google Account and requests Gmail read-only access
  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      debugPrint('Google Sign-In notice: $e');
      return null;
    }
  }

  /// Disconnects Google Account
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Fetches recent billing, invoice, and utility emails from Gmail API (past 30 days)
  static Future<List<EmailStatementMessage>> fetchRecentBillEmails({int maxResults = 25}) async {
    try {
      var account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      if (account == null) return [];

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('Gmail API: Access token unavailable');
        return [];
      }

      // Query Gmail API for statements, bills, utilities from last 30 days
      final query = Uri.encodeComponent(
        'newer_than:30d (category:updates OR label:important OR bill OR invoice OR statement OR payment OR electricity OR recharge OR due)',
      );
      final listUri = Uri.parse(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages?q=$query&maxResults=$maxResults',
      );

      final listResponse = await http.get(
        listUri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (listResponse.statusCode != 200) {
        debugPrint('Gmail API list returned status ${listResponse.statusCode}: ${listResponse.body}');
        return [];
      }

      final listData = jsonDecode(listResponse.body) as Map<String, dynamic>;
      final messagesList = listData['messages'] as List<dynamic>? ?? [];

      final results = <EmailStatementMessage>[];

      for (final msgRef in messagesList) {
        final msgId = msgRef['id']?.toString();
        if (msgId == null) continue;

        try {
          final detailUri = Uri.parse(
            'https://gmail.googleapis.com/gmail/v1/users/me/messages/$msgId?format=metadata&metadataHeaders=From&metadataHeaders=Subject&metadataHeaders=Date',
          );
          final detailRes = await http.get(
            detailUri,
            headers: {'Authorization': 'Bearer $accessToken'},
          );

          if (detailRes.statusCode == 200) {
            final detailData = jsonDecode(detailRes.body) as Map<String, dynamic>;
            final snippet = detailData['snippet']?.toString() ?? '';
            final payload = detailData['payload'] as Map<String, dynamic>? ?? {};
            final headers = payload['headers'] as List<dynamic>? ?? [];

            String from = '';
            String subject = '';
            DateTime date = DateTime.now();

            for (final h in headers) {
              final name = h['name']?.toString().toLowerCase();
              final val = h['value']?.toString() ?? '';
              if (name == 'from') from = val;
              if (name == 'subject') subject = val;
              if (name == 'date') {
                try {
                  date = DateTime.parse(val);
                } catch (_) {}
              }
            }

            results.add(EmailStatementMessage(
              id: msgId,
              from: from,
              subject: subject,
              snippet: '$subject - $snippet',
              date: date,
            ));
          }
        } catch (e) {
          debugPrint('Error fetching email details: $e');
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error syncing Gmail messages: $e');
      return [];
    }
  }
}
