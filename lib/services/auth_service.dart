import 'package:dio/dio.dart';
import 'package:hanout_frontend/constants.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import jdid
import '../models/auth_response.dart';

class AuthService {
  final Dio _dio = Dio();
  final String baseUrl = AppConstants.authUrl;

  // --- Fonction bach n-7fdo l-token f l-phone ---
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // --- Fonction dyal Logout ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ==================== LOGIN ====================
  Future<AuthResponse?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        "$baseUrl/login",
        data: {"email": email, "password": password},
      );

      if (response.statusCode == 200) {
        final authData = AuthResponse.fromJson(response.data);
        // --- STOKI L-TOKEN HNA ---
        await _saveToken(authData.idToken);
        return authData;
      }
    } on DioException catch (e) {
      print("Login Error: ${e.response?.data ?? e.message}");
    }
    return null;
  }

  // ==================== REGISTER ====================
  Future<AuthResponse?> register({
    required String email,
    required String password,
    required String shopName,
    String? ownerName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        "$baseUrl/register",
        data: {
          "email": email,
          "password": password,
          "shopName": shopName,
          "ownerName": ownerName,
          "phoneNumber": phoneNumber,
        },
      );

      if (response.statusCode == 200) {
        final authData = AuthResponse.fromJson(response.data);
        // --- STOKI L-TOKEN HNA ---
        await _saveToken(authData.idToken);
        return authData;
      }
    } on DioException catch (e) {
      print("Register Error: ${e.response?.data ?? e.message}");
    }
    return null;
  }
}
