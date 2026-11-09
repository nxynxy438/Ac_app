import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Result of a login attempt.
class LoginResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? user; // firstName, lastName, photoPath, ...
  final String? accountNumber;

  LoginResult({
    required this.success,
    required this.message,
    this.user,
    this.accountNumber,
  });
}

class LoginApi {
  // Android emulator : http://10.0.2.2:3000
  // Real phone       : http://<your PC IP>:3000
  static const String baseUrl = 'http://10.0.2.2:3000';

  /// Log in with the email + PIN the user created at registration.
  static Future<LoginResult> login(String email, String pin) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v1/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'pin': pin}),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        return LoginResult(
          success: true,
          message: 'Login successful',
          user: data['user'] as Map<String, dynamic>?,
          accountNumber: data['accountNumber']?.toString(),
        );
      }
      return LoginResult(
        success: false,
        message: data['message']?.toString() ?? 'Login failed',
      );
    } on SocketException {
      return LoginResult(success: false, message: 'Cannot reach the server');
    } on TimeoutException {
      return LoginResult(success: false, message: 'Server took too long');
    } catch (e) {
      return LoginResult(success: false, message: 'Error: $e');
    }
  }
}

// ---------------------------------------------------------------
// HOW TO USE inside your login screen:
//
//   final result = await LoginApi.login(emailCtrl.text, pinCtrl.text);
//   if (!mounted) return;
//   if (result.success) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const HomeScreen()),
//     );
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(result.message), backgroundColor: Colors.red),
//     );
//   }
// ---------------------------------------------------------------