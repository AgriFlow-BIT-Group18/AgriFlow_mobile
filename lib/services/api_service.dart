import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  static const String emulatorUrl = 'http://10.0.2.2:5000/api';

  static String get _baseUrl {
    if (kIsWeb) return baseUrl;
    return emulatorUrl;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

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
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
            'Cannot reach server. Please ensure the backend is running.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String role, {String? region}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
              if (region != null) 'region': region,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data));
        return data;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
            'Cannot reach server. Please ensure the backend is running.');
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getProducts() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/products'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load products');
  }

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> orderItems,
    required Map<String, String> shippingAddress,
    required double totalPrice,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: _headers(token),
      body: jsonEncode({
        'orderItems': orderItems,
        'shippingAddress': shippingAddress,
        'paymentMethod': 'Cash on Delivery',
        'totalPrice': totalPrice,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Failed to create order');
  }

  Future<List<dynamic>> getMyOrders() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/orders/myorders'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load orders');
  }

  Future<List<dynamic>> getAllOrders() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/orders'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load all orders');
  }

  Future<List<dynamic>> getDeliveries() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/deliveries'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load deliveries');
  }

  Future<List<dynamic>> getMyDeliveries() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/deliveries/my-deliveries'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load my deliveries');
  }

  Future<void> createProductReview(String productId, int rating, String comment) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/products/$productId/reviews'),
      headers: _headers(token),
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to add review');
    }
  }

  Future<Map<String, dynamic>> createDelivery(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/deliveries'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 201) return responseData;
    throw Exception(responseData['message'] ?? 'Failed to create delivery');
  }

  Future<List<dynamic>> getNearbyDistributors(double lat, double lng, {double distance = 10}) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/users/nearby-distributors?lat=$lat&lng=$lng&distance=$distance'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load nearby distributors');
  }

  Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null) {
        final Map<String, dynamic> currentUser = jsonDecode(userStr);
        final newUser = <String, dynamic>{...currentUser, ...responseData};
        await prefs.setString('user', jsonEncode(newUser));
      }
      return responseData;
    }
    throw Exception(responseData['message'] ?? 'Failed to update profile');
  }

  Future<void> updatePassword(String userId, String currentPassword, String newPassword) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: _headers(token),
      body: jsonEncode({
        'password': newPassword,
        'currentPassword': currentPassword, // Note: Backend update might need adjustment if it doesn't check currentPassword
      }),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update password');
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
  Future<List<dynamic>> getNotifications() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load notifications');
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/notifications/$notificationId/read'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<int> getUnreadNotificationCount() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/unread-count'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['count'];
    }
    return 0;
  }
}
