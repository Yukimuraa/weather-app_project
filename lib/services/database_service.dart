import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class DatabaseService {
  // Auto-detect the correct URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/weathercropsapp/api';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      // For physical device, you need to use your computer's IP address
      // Change this to your computer's IP if testing on physical device
      return 'http://10.0.2.2/weathercropsapp/api';
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost
      // For physical iOS device, use your computer's IP address
      return 'http://localhost/weathercropsapp/api';
    } else {
      return 'http://localhost/weathercropsapp/api';
    }
  }
  
  // Manual override - uncomment and set your IP if needed for physical device
  // static const String baseUrl = 'http://192.168.1.100/weathercropsapp/api';
  
  static const Duration _httpTimeout = Duration(seconds: 10);

  /// Register user to MySQL database
  /// 
  /// [email] - User's email address
  /// [password] - User's password (will be hashed on server)
  /// [firebaseUid] - Optional Firebase user ID if using Firebase Auth
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    String? firebaseUid,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/register.php');
      
      debugPrint('=== DATABASE SERVICE ===');
      debugPrint('Base URL: $baseUrl');
      debugPrint('Full URL: $url');
      debugPrint('Request body: email=$email, firebase_uid=$firebaseUid');
      
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'email': email.trim(),
              'password': password,
              'firebase_uid': firebaseUid,
            }),
          )
          .timeout(_httpTimeout);

      debugPrint('Database API Response Status: ${response.statusCode}');
      debugPrint('Database API Response Body: ${response.body}');

      // Handle non-JSON responses
      if (response.statusCode == 0) {
        throw Exception('Cannot connect to server. Please check:\n'
            '1. XAMPP Apache is running\n'
            '2. URL is correct: $baseUrl\n'
            '3. For physical device, use your computer\'s IP address');
      }

      // Try to parse JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Invalid server response. Make sure PHP is working.\n'
            'Response: ${response.body.substring(0, 200)}');
      }

      // Accept both 201 (created) and 200 (ok) status codes
      if ((response.statusCode == 201 || response.statusCode == 200) && 
          responseData['success'] == true) {
        debugPrint('User registered in database: ${responseData['email']}');
        debugPrint('User ID: ${responseData['user_id']}');
        return responseData;
      } else {
        final errorMessage = responseData['message'] ?? 
            'Registration failed (Status: ${response.statusCode})';
        debugPrint('Registration failed - Status: ${response.statusCode}');
        debugPrint('Response data: $responseData');
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      throw Exception('Cannot connect to server at $baseUrl\n'
          'Please check:\n'
          '1. XAMPP Apache is running\n'
          '2. For Android emulator, URL should be: http://10.0.2.2/weathercropsapp/api\n'
          '3. For physical device, use your computer\'s IP: http://YOUR_IP/weathercropsapp/api\n'
          'Error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}\n'
          'Please check your server connection.');
    } catch (e) {
      if (e.toString().contains('TimeoutException') || 
          e.toString().contains('timeout')) {
        throw Exception('Connection timeout. Please check:\n'
            '1. XAMPP Apache is running\n'
            '2. Server URL is correct: $baseUrl\n'
            '3. Firewall is not blocking the connection');
      }
      rethrow;
    }
  }

  /// Test database connection and API endpoint
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final url = Uri.parse('$baseUrl/test.php');
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        return {
          'success': false,
          'message': 'Server returned status ${response.statusCode}',
          'database_status': 'unknown'
        };
      }
    } catch (e) {
      debugPrint('Database connection test failed: $e');
      return {
        'success': false,
        'message': 'Connection failed: ${e.toString()}',
        'database_status': 'failed'
      };
    }
  }
}
