import '../newchatpage.dart';
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
  static Future<List<UserDto>> getUsers() async {
    try {
      final response = await ApiClient.dio.get("/api/users");

      final data = response.data as List;

      return data.map((e) => UserDto.fromJson(e)).toList();
    } catch (e) {
      print("ERROR getUsers: $e");
      return [];
    }
  }
  static Future<String?> getUsernameById(String userId) async {
    try {
      final response = await ApiClient.dio.get("/api/users/$userId");

      return response.data?["username"];
    } catch (e) {
      print("ERROR getUsernameById: $e");
      return null;
    }
  }
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await ApiClient.dio.get(
        "/api/users",
        queryParameters: {"username": query},
      );

      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print("ERROR searchUsers: $e");
      return [];
    }
  }

  static Future<bool> sendVoiceRoomInvites({
    required int roomId,
    required List<String> receiverIds,
  }) async {
    try {
      await ApiClient.dio.post(
        "/api/voice/send-invite",
        data: {
          "roomId": roomId,
          "receiverIds": receiverIds,
        },
      );

      return true;
    } catch (e) {
      print("ERROR sendVoiceRoomInvites: $e");
      return false;
    }
  }
// ================= SAVED POSTS =================
// ================= USERS =================

  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await ApiClient.dio.get("/api/users/$userId");
      return response.data;
    } catch (e) {
      print("ERROR getUserById: $e");
      return null;
    }
  }
  static Future<List<Map<String, dynamic>>> getSavedPosts({
    required int limit,
    required int offset,
  }) async {
    try {
      final response = await ApiClient.dio.get(
        "/api/posts/save/me",
        queryParameters: {
          "limit": limit,
          "offset": offset,
        },
      );

      final List data = response.data;

      return List<Map<String, dynamic>>.from(data)
          .map((p) => {
        ...p,
        "votes_count": p["netScore"] ?? 0,
        "user_vote": p["userVote"] ?? 0,
        "created_at": p["createdAt"],
      })
          .toList();
    } catch (e) {
      print("ERROR getSavedPosts: $e");
      return [];
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
  // ================= VOICE INVITES =================

  static Future<List<Map<String, dynamic>>> getMyInvites() async {
    try {
      final response = await ApiClient.dio.get("/api/voice/my-invites");
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print("ERROR getMyInvites: $e");
      return [];
    }
  }

  static Future<bool> acceptInvite(int inviteId) async {
    try {
      await ApiClient.dio.post("/api/voice/accept-invite/$inviteId");
      return true;
    } catch (e) {
      print("ERROR acceptInvite: $e");
      return false;
    }
  }

  static Future<bool> rejectInvite(int inviteId) async {
    try {
      await ApiClient.dio.post("/api/voice/reject-invite/$inviteId");
      return true;
    } catch (e) {
      print("ERROR rejectInvite: $e");
      return false;
    }
  }
}