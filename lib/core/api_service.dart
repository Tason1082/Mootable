import '../core/api_client.dart';

class ApiService {
  static Future<List<Map<String, dynamic>>> getMyCommunities() async {
    try {
      final response = await ApiClient.dio.get(
        "/api/communities/my",
      );

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception("API Error: $e");
    }
  }
}