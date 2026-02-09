import 'package:flutter/material.dart';
import '../chat_page.dart';
import '../community/community_explore_page.dart';
import '../core/api_client.dart';
import '../post/post_page.dart';
import 'home_page.dart';

Future<void> fetchPosts(HomePageState state, {bool loadMore = false}) async {
  if (state.isLoadingMore || (!state.hasMore && loadMore)) return;

  try {
    if (!loadMore) {
      state.offset = 0;
      state.posts.clear();
      state.setState(() => state.loading = true);
    }

    state.setState(() => state.isLoadingMore = true);

    final page = (state.offset ~/ state.limit) + 1;

    final response = await ApiClient.dio.get(
      "/api/posts",
      queryParameters: {
        "page": page,
        "pageSize": state.limit,
      },
    );

    final raw = List<Map<String, dynamic>>.from(response.data);

    final posts = raw.map((p) {
      return {
        ...p, // Backend'den gelen her şey aynen kalsın

        // Sadece tarih ve community için mapping
        "created_at": p["createdAt"],
        "community_name": p["community"],
      };
    }).toList();

    state.setState(() {
      state.posts.addAll(posts);
      state.offset += state.limit;
      state.hasMore = posts.length == state.limit;
      state.loading = false;
      state.isLoadingMore = false;
    });
  } catch (e) {
    state.setState(() {
      state.loading = false;
      state.isLoadingMore = false;
    });
  }
}


/// =======================================================
/// JOIN COMMUNITY (API)
/// =======================================================
Future<void> joinCommunity(
    HomePageState state,
    String communityId,
    int postIndex,
    ) async {
  try {
    await ApiClient.dio.post(
      "/api/communities/join",
      data: {"communityId": communityId},
    );

    state.setState(() {
      state.posts[postIndex]["is_member"] = true;
    });
  } catch (_) {}
}







/// =======================================================
/// TOGGLE VOTE (API ONLY)
/// =======================================================
Future<void> toggleVote(HomePageState state, int postId, int vote) async {
  final index = state.posts.indexWhere((p) => p["id"] == postId);
  if (index == -1) return;

  final post = state.posts[index];

  final previousVote = post["user_vote"] ?? 0;
  final previousCount = post["votes_count"] ?? 0;

  /// optimistic UI
  state.setState(() {
    if (previousVote == vote) {
      post["user_vote"] = 0;
      post["votes_count"] = previousCount - vote;
    } else {
      post["user_vote"] = vote;
      post["votes_count"] = previousCount - previousVote + vote;
    }
  });

  try {
    final res = await ApiClient.dio.post(
      "/api/posts/vote",
      data: {
        "postId": postId,
        "vote": vote,
      },
    );

    post["votes_count"] = res.data["score"];
  } catch (_) {
    state.setState(() {
      post["user_vote"] = previousVote;
      post["votes_count"] = previousCount;
    });
  }
}










/// =======================================================
/// TOGGLE SAVE (API ONLY)
/// =======================================================
Future<void> toggleSave(
    HomePageState state,
    int postId,
    bool currentlySaved,
    ) async {
  final index = state.posts.indexWhere((p) => p["id"] == postId);
  if (index == -1) return;

  state.setState(() {
    state.posts[index]["is_saved"] = !currentlySaved;
  });

  try {
    await ApiClient.dio.post(
      "/api/posts/save",
      data: {"postId": postId},
    );
  } catch (_) {
    state.setState(() {
      state.posts[index]["is_saved"] = currentlySaved;
    });
  }
}










/// =======================================================
/// NAVIGATION
/// =======================================================
void onItemTapped(HomePageState state, int index) {
  if (index == 1) {
    Navigator.push(
      state.context,
      MaterialPageRoute(builder: (_) => const CommunityExplorePage()),
    );
  } else if (index == 2) {
    Navigator.push(
      state.context,
      MaterialPageRoute(builder: (_) => const PostAddPage()),
    ).then((value) {
      if (value == true) {
        state.offset = 0;
        state.posts.clear();
        state.hasMore = true;
        fetchPosts(state);
      }
    });
  } else if (index == 3) {
    Navigator.push(
      state.context,
      MaterialPageRoute(
        builder: (_) => const DefaultTabController(
          length: 3,
          child: ChatPage(),
        ),
      ),
    );
  } else {
    state.setState(() => state.selectedIndex = index);
  }
}

