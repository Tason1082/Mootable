import 'package:dio/dio.dart';
import '../core/api_client.dart';

class AuthApi {
  static Future<String> register(String email, String password) async {
    final response = await ApiClient.dio.post(
      "/api/auth/register",
      data: {
        "email": email,
        "password": password
      },
    );

    return response.data["token"];
  }
}