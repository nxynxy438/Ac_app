import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'user_session.dart';

/// Sends every transaction (own transfer / phone top-up) to the Node backend
/// so it shows up in Admin > History Transaction.
///
/// If the server can't be reached the transaction waits in a queue and is
/// sent again together with the next transaction, so nothing is lost.
class TransactionSync {
  TransactionSync._();

  static final List<Map<String, dynamic>> _queue = [];
  static bool _flushing = false;

  // Reads the logged-in user's email without depending on how UserSession
  // names it. Returns '' if it can't be found.
  static String _email() {
    try {
      final dynamic session = UserSession.instance;
      final v = session.email;
      return v == null ? '' : v.toString();
    } catch (_) {
      return '';
    }
  }

  /// Queue [txn] and try to upload everything waiting. Never throws.
  static Future<void> send(Map<String, dynamic> txn) async {
    _queue.add({...txn, 'email': _email()});
    await _flush();
  }

  static Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      while (_queue.isNotEmpty) {
        final ok = await _post(_queue.first);
        if (!ok) break; // server unreachable: keep the rest for next time
        _queue.removeAt(0);
      }
    } finally {
      _flushing = false;
    }
  }

  static Future<bool> _post(Map<String, dynamic> item) async {
    try {
      final res = await http
          .post(
            Uri.parse('${UserSession.baseUrl}/api/v1/transactions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(item),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) return true;

      // 4xx = the server refused this record for good. Drop it so it can't
      // block the queue forever. 5xx = temporary, keep it and retry later.
      return res.statusCode >= 400 && res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}