import 'api_client.dart';

class AuthApi {
  static Future<String> register(String email, String password) async {
    final response = await ApiClient.dio.post(
      "/api/auth/register",
      data: {
        "email": email,
        "password": password
      },
    );

    final data = response.data;

    // 🔥 AYNI POSTS MANTIĞI
    if (data["success"] != true) {
      throw Exception(data["message"]);
    }

    return data["data"]["token"];
  }
}