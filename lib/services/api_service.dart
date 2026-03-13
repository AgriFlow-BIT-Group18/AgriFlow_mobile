import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator to access localhost
  // Use localhost for Web/iOS Simulator/Physical devices (if proxied)
  static const String baseUrl = 'http://localhost:5000/api';
  static const String emulatorUrl = 'http://10.0.2.2:5000/api';

  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    // On physical Android device, you'd need the IP of your machine (e.g., 192.168.1.5)
    return emulatorUrl;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      print('Login response status: \${response.statusCode}');
      print('Login response body: \${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data));
        return data;
      } else {
        throw Exception(data['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      print('Login error: \$e');
      if (e.toString().contains('Connection refused') || e.toString().contains('Timeout')) {
        throw Exception('Cannot connect to server at \$_baseUrl. Make sure the backend is running.');
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$_baseUrl/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \$token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }
}
