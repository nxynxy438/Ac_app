import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:3000/api/v1";

  // ==========================================
  // TRANSFER MONEY
  // ==========================================

  static Future<bool> transferMoney({
    required String token,
    required String recipientAccount,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/client/transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipientAccount': recipientAccount,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Server error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Network error: $e");
      return false;
    }
  }

  // ==========================================
  // LOGIN (email + password -> sends OTP)
  // ==========================================

  /// Calls POST /api/v1/auth/request-otp
  /// Returns a map like {'success': true} or {'success': false, 'message': '...'}
  static Future<Map<String, dynamic>> requestOtp(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print("Network error: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ==========================================
  // RESEND OTP (email only, no password needed)
  // ==========================================

  /// Calls POST /api/v1/auth/resend-otp
  /// Returns true if the email was resent successfully.
  static Future<bool> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        print("Resend OTP error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Network error: $e");
      return false;
    }
  }

  // ==========================================
  // VERIFY OTP
  // ==========================================

  /// Calls POST /api/v1/auth/verify-otp
  /// Returns a map like {'success': true, 'token': '...'} or {'success': false, 'message': '...'}
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print("Network error: $e");
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}