import 'package:flutter/material.dart';
import '../chat_page.dart';
import '../community/community_explore_page.dart';
import '../core/api_client.dart';
import '../core/api_helper.dart';
import '../post/post_page.dart';
import 'home_page.dart';
Future<void> fetchPosts(
    dynamic state, {
      bool loadMore = false,
    }) async {
  if (state.isLoadingMore) return;

  if (loadMore && !state.hasMore) return;

  try {
    if (!loadMore) {
      state.setState(() {
        state.loading = true;
      });
    }

    state.isLoadingMore = true;

    final page = loadMore
        ? ((state.offset ~/ state.limit) + 1)
        : 1;

    final response = await ApiClient.dio.get(
      "/api/posts",
      queryParameters: {
        "page": page,
        "pageSize": state.limit,
      },
    );

    final api = ApiHelper.parse<List>(
      response,
          (json) => List.from(json ?? []),
    );

    final raw = api.data ?? [];



    final List<Map<String, dynamic>> fetchedPosts = [];

    for (final item in raw) {
      final p = Map<String, dynamic>.from(item);

      final mappedPost = {
        ...p,
        "votes_count": p["netScore"] ?? 0,
        "user_vote": p["userVote"] ?? 0,
        "created_at": p["createdAt"],
        "communityName": p["communityName"],
        "medias": p["medias"] ?? [],
        "commentCount": p["commentCount"] ?? 0,
      };

      final postId = mappedPost["id"];

      state.postKeys.putIfAbsent(
        postId,
            () => GlobalKey(
          debugLabel: 'post_$postId',
        ),
      );

      fetchedPosts.add(mappedPost);
    }

    if (!state.mounted) return;

    state.setState(() {
      if (loadMore) {
        state.posts.addAll(fetchedPosts);
      } else {
        final Map<dynamic, Map<String, dynamic>> merged = {
          for (var post in state.posts)
            post["id"]: Map<String, dynamic>.from(post),
        };

        for (final post in fetchedPosts) {
          merged[post["id"]] = post;
        }

        state.posts = merged.values.toList()
          ..sort((a, b) {
            final aDate = DateTime.parse(a["created_at"]);
            final bDate = DateTime.parse(b["created_at"]);

            return bDate.compareTo(aDate);
          });
      }

      state.offset = state.posts.length;

      state.hasMore = fetchedPosts.length >= state.limit;

      state.loading = false;
    });
  } catch (e) {
    debugPrint("FETCH POSTS ERROR: $e");

    if (!state.mounted) return;

    state.setState(() {
      state.loading = false;
    });
  } finally {
    state.isLoadingMore = false;
  }
}

/// =======================================================
/// =======================================================
/// JOIN COMMUNITY (API)
/// =======================================================
Future<void> joinCommunity(
    dynamic state,
    String communityId,
    int postIndex,
    ) async {
  try {
    final res = await ApiClient.dio.post(
      "/api/communities/join",
      data: {"communityId": communityId},
    );

    ApiHelper.parse<dynamic>(res, null);

    state.setState(() {
      state.posts[postIndex]["is_member"] = true;
    });
  } catch (e) {
    debugPrint("JOIN COMMUNITY ERROR: $e");
  }
}

/// =======================================================
/// TOGGLE VOTE
/// =======================================================
Future<void> toggleVote(
    dynamic state,
    int postId,
    int vote,
    ) async {
  final index =
  state.posts.indexWhere((p) => p["id"] == postId);

  if (index == -1) return;

  final post = state.posts[index];

  try {
    final res = await ApiClient.dio.post(
      "/api/posts/$postId/vote",
      data: {"vote": vote},
    );

    final api =
    ApiHelper.parse<Map<String, dynamic>>(
      res,
          (json) => Map<String, dynamic>.from(json),
    );

    final voteData = api.data;

    if (voteData == null) return;

    state.setState(() {
      post["user_vote"] = voteData["userVote"] ?? 0;
      post["votes_count"] = voteData["score"] ?? 0;
    });
  } catch (e) {
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(
        content: Text("Oy verilemedi: $e"),
      ),
    );
  }
}

/// =======================================================
/// TOGGLE SAVE
/// =======================================================
Future<void> toggleSave(
    dynamic state,
    int postId,
    bool currentlySaved,
    ) async {
  final index =
  state.posts.indexWhere((p) => p["id"] == postId);

  if (index == -1) return;

  state.setState(() {
    state.posts[index]["is_saved"] =
    !currentlySaved;
  });

  try {
    final res = await ApiClient.dio.post(
      "/api/posts/save",
      data: {"postId": postId},
    );

    final api =
    ApiHelper.parse<Map<String, dynamic>>(
      res,
          (json) => Map<String, dynamic>.from(json),
    );

    final saved =
        api.data?["saved"] ?? false;

    state.setState(() {
      state.posts[index]["is_saved"] = saved;
    });
  } catch (e) {
    state.setState(() {
      state.posts[index]["is_saved"] =
          currentlySaved;
    });

    debugPrint(
      "TOGGLE SAVE ERROR: $e",
    );
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

