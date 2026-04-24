import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'supabase_service.dart';

class ApiService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SupabaseService.client.auth.currentSession?.accessToken ?? ""}',
      };

  // Categories
  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/inventory/categories'), headers: _headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load categories');
  }

  static Future<Map<String, dynamic>> createCategory(String name) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/inventory/categories'),
      headers: _headers,
      body: json.encode({"name": name}),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to create category');
  }

  static Future<void> deleteCategory(String id) async {
    final response = await http.delete(Uri.parse('${AppConstants.baseUrl}/inventory/categories/$id'), headers: _headers);
    if (response.statusCode != 200) throw Exception(json.decode(response.body)['detail'] ?? 'Failed to delete category');
  }

  // Inventory
  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/inventory/products'), headers: _headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load products');
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/inventory/products'),
      headers: _headers,
      body: json.encode(productData),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to create product');
  }

  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/inventory/products/$id'),
      headers: _headers,
      body: json.encode(productData),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to update product');
  }

  static Future<void> initPasswordChange(String newPassword) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/password/change/init'),
      headers: _headers,
      body: json.encode({"new_password": newPassword}),
    );
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to send OTP');
    }
  }

  static Future<void> confirmPasswordChange(String otp) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/password/change/confirm'),
      headers: _headers,
      body: json.encode({"otp": otp}),
    );
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Failed to verify OTP');
    }
  }

  static Future<void> deleteProduct(String id) async {
    final response = await http.delete(Uri.parse('${AppConstants.baseUrl}/inventory/products/$id'), headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to delete product');
  }

  // Orders
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/orders/create'),
      headers: _headers,
      body: json.encode(orderData),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(json.decode(response.body)['detail'] ?? 'Failed to create order');
  }

  static Future<List<dynamic>> getOrderHistory() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/orders/history'), headers: _headers);
    if (response.statusCode == 200) return json.decode(response.body);
    
    final errorData = json.decode(response.body);
    throw Exception(errorData['detail'] ?? 'Failed to load history (Status: ${response.statusCode})');
  }

  static Future<List<dynamic>> getUnifiedHistory() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/orders/unified-history'), headers: _headers);
    _handleResponse(response);
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> getOrderDetails(String id) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/orders/$id'), headers: _headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load order details');
  }

  // Analytics
  static Future<Map<String, dynamic>> getAnalyticsSummary({String period = "all"}) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/analytics/summary?period=$period'), headers: _headers);
    _handleResponse(response);
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> getInventoryStatus() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/analytics/inventory-status'), headers: _headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load inventory status');
  }

  // Customers (Khata)
  static Future<List<dynamic>> getCustomers() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/customers/'), headers: _headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load customers');
  }

  static Future<Map<String, dynamic>> createOrGetCustomer(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/customers/'),
      headers: _headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to save customer');
  }

  static Future<List<dynamic>> getCustomerOrders(String customerId) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/customers/$customerId/orders'), headers: _headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load customer orders');
  }

  static Future<Map<String, dynamic>> getCustomerSummary(String customerId) async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/customers/$customerId/summary'), headers: _headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load customer summary');
  }

  static Future<void> recordPayment(String customerId, double amount) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/customers/$customerId/payments'),
      headers: _headers,
      body: json.encode({"amount": amount}),
    );
    if (response.statusCode != 200) throw Exception('Failed to record payment');
  }

  static Future<Map<String, dynamic>> getCreditSummary() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/customers/summary/credit'), headers: _headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load credit summary');
  }

  // Auth & Profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/auth/profile'), headers: _headers);
    _handleResponse(response);
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/profile'),
      headers: _headers,
      body: json.encode(profileData),
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to update profile');
  }


  // Notifications
  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(Uri.parse('${AppConstants.baseUrl}/notifications'), headers: _headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load notifications');
  }

  static Future<void> markNotificationAsRead(String id) async {
    await http.post(Uri.parse('${AppConstants.baseUrl}/notifications/$id/read'), headers: _headers);
  }

  static Future<void> deleteNotification(String id) async {
    await http.delete(Uri.parse('${AppConstants.baseUrl}/notifications/$id'), headers: _headers);
  }

  // Custom Auth Flow (OTP)
  static Future<void> initSignup(String email, String password, String name, String shopName) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/signup/init'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({"email": email, "password": password, "full_name": name, "shop_name": shopName}),
    );
    if (response.statusCode != 200) throw Exception(json.decode(response.body)['detail'] ?? 'Failed to send OTP');
  }

  static Future<void> verifySignup(String email, String password, String name, String shopName, String otp) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/signup/verify'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "email": email,
        "password": password,
        "full_name": name,
        "shop_name": shopName,
        "otp": otp,
      }),
    );
    if (response.statusCode != 200) throw Exception(json.decode(response.body)['detail'] ?? 'Invalid OTP');
  }

  static void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      // Token is invalid/expired. This can happen after a password change.
      // We don't have direct access to AuthProvider here, but the next time the app 
      // checks auth state or tries to use the client, it will see the 401.
      // For now, we just throw a specific exception.
      throw UnauthorizedException();
    }
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['detail'] ?? 'Request failed with status: ${response.statusCode}');
    }
  }
}

class UnauthorizedException implements Exception {
  final String message = "Session expired. Please login again.";
  @override
  String toString() => message;
}
