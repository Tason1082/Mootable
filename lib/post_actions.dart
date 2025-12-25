import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home/home_page.dart';


class PostActions {
  /// ---------------- FETCH POSTS ----------------
  static Future<void> fetchPosts(HomePageState state,
      {bool loadMore = false}) async {
    if (state.isLoadingMore || (!state.hasMore && loadMore)) return;

    if (!loadMore) state.setState(() => state.loading = true);
    state.setState(() => state.isLoadingMore = true);

    final posts = List<Map<String, dynamic>>.from(
      await Supabase.instance.client
          .from("posts")
          .select("id, content, image_url, created_at, user_id, community")
          .order("created_at", ascending: false)
          .range(state.offset, state.offset + state.limit - 1),
    );

    if (posts.isEmpty) {
      state.setState(() {
        state.hasMore = false;
        state.isLoadingMore = false;
        state.loading = false;
      });
      return;
    }

    List<Map<String, dynamic>> postsWithExtras = [];

    for (final post in posts) {
      final String communityId = post["community"];

      final communityMap = await Supabase.instance.client
          .from("communities")
          .select("name")
          .eq("id", communityId)
          .maybeSingle();

      final memberMap = await Supabase.instance.client
          .from("user_communities")
          .select("id")
          .eq("community_id", communityId)
          .eq("user_id", state.user!.id)
          .maybeSingle();

      final votesList = List<Map<String, dynamic>>.from(
        await Supabase.instance.client
            .from("votes")
            .select("user_id, vote")
            .eq("post_id", post["id"]),
      );

      final commentsList = List<Map<String, dynamic>>.from(
        await Supabase.instance.client
            .from("comments")
            .select("id")
            .eq("post_id", post["id"]),
      );

      final savedMap = await Supabase.instance.client
          .from("saves")
          .select("id")
          .eq("post_id", post["id"])
          .eq("user_id", state.user!.id)
          .maybeSingle();

      final upvotes = votesList.where((v) => v["vote"] == 1).length;
      final downvotes = votesList.where((v) => v["vote"] == -1).length;

      final userVote = votesList.firstWhere(
            (v) => v["user_id"] == state.user!.id,
        orElse: () => {"vote": 0},
      )["vote"];

      postsWithExtras.add({
        ...post,
        "community_name": communityMap?["name"] ?? "Bilinmeyen Topluluk",
        "votes_count": upvotes - downvotes,
        "user_vote": userVote,
        "comment_count": commentsList.length,
        "is_saved": savedMap != null,
        "is_member": memberMap != null,
      });
    }

    state.setState(() {
      if (loadMore) {
        state.posts.addAll(postsWithExtras);
      } else {
        state.posts = postsWithExtras;
      }

      state.offset += state.limit;
      state.hasMore = posts.length == state.limit;
      state.isLoadingMore = false;
      state.loading = false;
    });
  }

  /// ---------------- JOIN COMMUNITY ----------------
  static Future<void> joinCommunity(
      HomePageState state,
      String communityId,
      int postIndex,
      ) async {
    try {
      await Supabase.instance.client.from("user_communities").insert({
        "community_id": communityId,
        "user_id": state.user!.id,
      });

      state.setState(() {
        state.posts[postIndex]["is_member"] = true;
      });

      ScaffoldMessenger.of(state.context).showSnackBar(
        const SnackBar(content: Text("Topluluğa katıldın 🎉")),
      );
    } catch (e) {
      ScaffoldMessenger.of(state.context).showSnackBar(
        const SnackBar(content: Text("Topluluğa katılamadın")),
      );
    }
  }

  /// ---------------- TOGGLE VOTE ----------------
  static Future<void> toggleVote(
      HomePageState state,
      int postId,
      int vote,
      ) async {
    final userId = state.user?.id;
    if (userId == null) return;

    final index = state.posts.indexWhere((p) => p["id"] == postId);
    if (index == -1) return;

    final post = state.posts[index];
    final int previousVote = post["user_vote"] ?? 0;
    final int previousCount = post["votes_count"] ?? 0;

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
      final existingVote = await Supabase.instance.client
          .from("votes")
          .select("vote")
          .eq("post_id", postId)
          .eq("user_id", userId)
          .maybeSingle();

      if (existingVote != null) {
        if (existingVote["vote"] == vote) {
          await Supabase.instance.client
              .from("votes")
              .delete()
              .eq("post_id", postId)
              .eq("user_id", userId);
        } else {
          await Supabase.instance.client
              .from("votes")
              .update({"vote": vote})
              .eq("post_id", postId)
              .eq("user_id", userId);
        }
      } else {
        await Supabase.instance.client.from("votes").insert({
          "post_id": postId,
          "user_id": userId,
          "vote": vote,
        });
      }
    } catch (_) {
      state.setState(() {
        post["user_vote"] = previousVote;
        post["votes_count"] = previousCount;
      });
    }
  }

  /// ---------------- TOGGLE SAVE ----------------
  static Future<void> toggleSave(
      HomePageState state,
      int postId,
      bool currentlySaved,
      ) async {
    final userId = state.user?.id;
    if (userId == null) return;

    final index = state.posts.indexWhere((p) => p["id"] == postId);
    if (index == -1) return;

    state.setState(() {
      state.posts[index]["is_saved"] = !currentlySaved;
    });

    try {
      if (currentlySaved) {
        await Supabase.instance.client
            .from("saves")
            .delete()
            .eq("post_id", postId)
            .eq("user_id", userId);
      } else {
        await Supabase.instance.client.from("saves").insert({
          "post_id": postId,
          "user_id": userId,
        });
      }
    } catch (_) {
      state.setState(() {
        state.posts[index]["is_saved"] = currentlySaved;
      });
    }
  }
}
