import 'package:flutter/material.dart';
import '../chat_page.dart';
import '../community/community_explore_page.dart';
import '../core/api_client.dart';
import '../post/post_page.dart';
import 'home_page.dart';

Future<void> fetchPosts(dynamic state, {bool loadMore = false}) async {
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

    // 🔥 BACKEND WRAPPER FIX
    final data = response.data;
    debugPrint("RESPONSE: ${response.data.runtimeType}");
    debugPrint("RESPONSE BODY: ${response.data}");
    if (data["success"] != true) {
      throw Exception(data["message"]);
    }

    final List raw = data["data"] ?? [];

    final posts = raw.map((item) {
      final p = Map<String, dynamic>.from(item); // 🔥 KRİTİK SATIR

      return {
        ...p,

        "votes_count": p["netScore"] ?? 0,
        "user_vote": p["userVote"] ?? 0,

        "created_at": p["createdAt"],
        "community_name": p["community"],

        "medias": p["medias"] ?? [],
        "commentCount": p["commentCount"] ?? 0,
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
    debugPrint("FETCH POSTS ERROR: $e");

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
    dynamic state,
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






Future<void> toggleVote(dynamic state, int postId, int vote) async {
  final index = state.posts.indexWhere((p) => p["id"] == postId);
  if (index == -1) return;

  final post = state.posts[index];

  try {
    final res = await ApiClient.dio.post(
      "/api/posts/$postId/vote",
      data: {"vote": vote},
    );

    final data = res.data;

    // Backend authoritative response ile state güncelle
    if (data != null) {
      state.setState(() {
        post["user_vote"] = data["userVote"];
        post["votes_count"] = data["score"];
      });
    }
  } catch (e) {
    // Hata durumunda kullanıcıya bildirim verebilirsin
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(content: Text("Oy verilemedi: $e")),
    );
  }
}




/// =======================================================
/// TOGGLE SAVE (API ONLY)
/// =======================================================
Future<void> toggleSave(
    dynamic state,
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

