import 'package:enshield_app/services/api_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:enshield_app/routes.dart';

class AuthService {
  /// Login with email & password
  static Future<dynamic> login(String email, String password) async {
    try {
      final response = await ApiService.post(
        '/api/auth/flutter-login',
        {
          "email": email,
          "password": password,
        },
      );

      // ✅ If token is received, store it for later API calls
      if (response != null && response['token'] != null) {
        ApiService.setToken(response['token']);
      }

      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Logout and clear all data
  static Future<void> logout() async {
    try {
      // Call API to invalidate token (optional, but good practice)
      // We don't await this because we want to logout locally regardless of server status
      ApiService.post('/api/auth/flutter-logout', {}).catchError((e) => print('Logout API error: $e'));
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Clear all local storage
      final storage = GetStorage();
      await storage.erase();
      
      // Clear API token specifically (redundant but safe)
      ApiService.clearToken();
      
      // Navigate to sign in
      Get.offAllNamed(Routes.signin);
    }
  }
}
