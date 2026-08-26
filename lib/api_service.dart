import 'dart:convert';
import 'package:http/http.dart' as http; // Make sure http package is installed

class ApiService {
  static const String baseUrl = "http://10.0.2.2:3000/api/v1";
  
  static Future<bool> transferMoney({
    required String token,
    required String recipientAccount,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transfer'), // Replace with your actual backend route
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipientAccount': recipientAccount,
          'amount': amount,
        }),
      );

      // Return true if status code is 200 or 201 (Success)
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
}