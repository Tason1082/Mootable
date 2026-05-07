import 'package:flutter/material.dart';
import 'package:mootable/post/post_grid_page.dart';
import '../core/api_client.dart';


class MyPostsPage extends StatelessWidget {
  const MyPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PostsGridPage(
      title: "My Posts",
      fetcher: (limit, offset) async {
        final res = await ApiClient.dio.get(
          '/api/posts/me',
          queryParameters: {
            "limit": limit,
            "offset": offset,
          },
        );

        final List raw = res.data["data"] ?? [];

        return raw.map<Map<String, dynamic>>((p) {
          final map = Map<String, dynamic>.from(p);

          return {
            ...map,
            "votes_count": map["netScore"] ?? 0,
            "user_vote": map["userVote"] ?? 0,
            "created_at": map["createdAt"],
            "comment_count": map["commentCount"] ?? 0,
          };
        }).toList();
      },
    );
  }
}