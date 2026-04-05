import 'api_client.dart';

class ApiService {

  // ================= POSTS SAVE =================

  static Future<bool> isPostSaved(int postId) async {
    try {
      final response = await ApiClient.dio.get("/api/posts/save/is_saved/$postId");
      return response.data?["isSaved"] == true;
    } catch (e) {
      print("ERROR isPostSaved: $e");
      return false;
    }
  }

  static Future<bool> toggleSavePost(int postId) async {
    try {
      final response = await ApiClient.dio.post(
        "/api/posts/save",
        data: {"postId": postId},
      );
      return response.data?["saved"] == true;
    } catch (e) {
      print("ERROR toggleSavePost: $e");
      return false;
    }
  }

  // ================= COMMUNITIES =================

  static Future<bool> isJoined(String communityId) async {
    try {
      final response = await ApiClient.dio.get("/api/communities/$communityId/is_joined");
      return response.data?["isJoined"] ?? false;
    } catch (e) {
      print("ERROR isJoined: $e");
      return false;
    }
  }

  static Future<void> joinCommunity(String communityId) async {
    try {
      await ApiClient.dio.post("/api/communities/$communityId/join");
    } catch (e) {
      print("ERROR joinCommunity: $e");
    }
  }

  static Future<void> leaveCommunity(String communityId) async {
    try {
      await ApiClient.dio.delete("/api/communities/$communityId/leave");
    } catch (e) {
      print("ERROR leaveCommunity: $e");
    }
  }

  // ================= MY COMMUNITIES =================

  static Future<List<Map<String, dynamic>>> getMyCommunities() async {
    try {
      final response = await ApiClient.dio.get("/api/communities/my");
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print("ERROR getMyCommunities: $e");
      return [];
    }
  }
}