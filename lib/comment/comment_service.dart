import 'package:flutter/foundation.dart';
import '../core/api_client.dart';

class CommentService {

  static Future<List<Map<String, dynamic>>> getComments(int postId) async {
    final res = await ApiClient.dio.get(
      '/api/comments/post/$postId',
    );

    final body = res.data;

    if (body is! Map || body["success"] != true) {
      return [];
    }

    final List raw = body["data"] ?? [];

    return raw.map<Map<String, dynamic>>((c) {
      final map = Map<String, dynamic>.from(c);

      return {
        ...map,
        "votes_count": map["netScore"] ?? 0,
        "user_vote": map["userVote"] ?? 0,
        "created_at": map["createdAt"],
        "replyCount": map["replyCount"] ?? 0,
      };
    }).toList();
  }

  static Future<bool> addComment(int postId, String content) async {
    final res = await ApiClient.dio.post(
      "/api/comments",
      data: {
        "postId": postId,
        "content": content,
      },
    );

    return res.data["success"] == true;
  }

  static Future<bool> addReply(int postId, int parentId, String content) async {
    final res = await ApiClient.dio.post(
      "/api/comments",
      data: {
        "postId": postId,
        "content": content,
        "parentId": parentId,
      },
    );

    return res.data["success"] == true;
  }

  static Future<bool> vote(int commentId, int vote) async {
    final res = await ApiClient.dio.post(
      "/api/comments/$commentId/vote2",
      data: {
        "vote": vote,
      },
    );

    return res.data["success"] == true;
  }

  static Future<bool> edit(int commentId, String content) async {
    final res = await ApiClient.dio.put(
      "/api/comments/$commentId",
      data: {
        "content": content,
      },
    );

    return res.data["success"] == true;
  }
}