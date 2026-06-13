import 'package:mootable/core/api_client.dart';

class UserService {
  static Future<Map<String, dynamic>> getMe() async {
    final res = await ApiClient.dio.get('/api/users/me');
    return Map<String, dynamic>.from(res.data);
  }
  static Future<Map<String, dynamic>> getUserByUsername(
      String username,
      ) async {
    final res = await ApiClient.dio.get(
      '/api/users/username/$username',
    );

    return Map<String, dynamic>.from(res.data);
  }

  static Future<List<Map<String, dynamic>>> getUserPosts(
      String username,
      ) async {
    final res = await ApiClient.dio.get(
      '/api/posts/user/$username',
    );

    final body = Map<String, dynamic>.from(res.data);
    final List rawList = body["data"] as List;

    return rawList.map<Map<String, dynamic>>((p) {
      final map = Map<String, dynamic>.from(p);

      return {
        ...map,
        "votes_count": map["netScore"] ?? 0,
        "user_vote": map["userVote"] ?? 0,
        "created_at": map["createdAt"],
        "community": map["community"],
        "communityId": map["communityId"],
        "comment_count": map["commentCount"] ?? 0,
      };
    }).toList();
  }

  static Future<void> updateProfile({
    required String username,
    required String bio,
  }) async {
    final Map<String, dynamic> data = {};

    if (username.trim().isNotEmpty) {
      data['username'] = username.trim();
    }

    if (bio.trim().isNotEmpty) {
      data['bio'] = bio.trim();
    }

    await ApiClient.dio.put(
      '/api/users',
      data: data,
    );
  }
}