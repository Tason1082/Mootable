import 'package:flutter/cupertino.dart';
import 'package:mootable/post/post_grid_page.dart';

import '../core/api_client.dart';

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PostsGridPage(
      title: "Saved Posts",
      fetcher: (limit, offset) async {
        try {
          final res = await ApiClient.dio.get(
            '/api/posts/save/me',
            queryParameters: {
              "limit": limit,
              "offset": offset,
            },
          );

          // 🔥 ApiResponse formatı
          final List raw = res.data["data"] ?? [];

          return raw.map<Map<String, dynamic>>((p) {
            final map = Map<String, dynamic>.from(p);

            return {
              ...map,

              // 🔥 UI uyumu
              "votes_count": map["netScore"] ?? 0,
              "user_vote": map["userVote"] ?? 0,
              "created_at": map["createdAt"],
              "comment_count": map["commentCount"] ?? 0,

              // 🔥 saved always true
              "is_saved": true,
            };
          }).toList();
        } catch (e) {
          debugPrint("SAVED POSTS ERROR: $e");
          return [];
        }
      },
    );
  }
}